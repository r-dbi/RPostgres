#ifndef __RPOSTGRES_PQ_CONNECTION__
#define __RPOSTGRES_PQ_CONNECTION__

#include <Rcpp.h>
#include <libpq-fe.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

class PqResult;

// convenience typedef for shared_ptr to PqConnection
class PqConnection;
typedef boost::shared_ptr<PqConnection> PqConnectionPtr;

// PqConnection ----------------------------------------------------------------

class PqConnection : boost::noncopyable {
  PGconn* pConn_;
  PqResult* pCurrentResult_;

public:
  PqConnection(std::vector<std::string> keys, std::vector<std::string> values):
               pCurrentResult_(NULL) {
    int n = keys.size();
    std::vector<const char*> c_keys(n + 1), c_values(n + 1);

    for (int i = 0; i < n; ++i) {
      c_keys[i] = keys[i].c_str();
      c_values[i] = values[i].c_str();
    }
    c_keys[n] = NULL;
    c_values[n] = NULL;

    pConn_ = PQconnectdbParams(&c_keys[0], &c_values[0], false);

    if (PQstatus(pConn_) != CONNECTION_OK) {
      std::string err = PQerrorMessage(pConn_);
      PQfinish(pConn_);
      Rcpp::stop(err);
    }

    PQsetClientEncoding(pConn_, "UTF-8");
  }

  virtual ~PqConnection() {
    try {
      PQfinish(pConn_);
    } catch(...) {}
  }

  PGconn* conn() {
    return pConn_;
  }

  // Cancels previous query, if needed.
  void setCurrentResult(PqResult* pResult) {
    if (pResult == pCurrentResult_)
      return;

    if (pCurrentResult_ != NULL) {
      if (pResult != NULL)
        Rcpp::warning("Cancelling previous query");

      con_check();
      PGcancel* cancel = PQgetCancel(pConn_);
      if (cancel == NULL)
        return;

      char errbuf[256];
      int rc = PQcancel(cancel, errbuf, 256);
      if (rc == 0)
        Rcpp::warning(errbuf);
      PQfreeCancel(cancel);
    }
    pCurrentResult_ = pResult;
  }

  bool isCurrentResult(PqResult* pResult) {
    return pCurrentResult_ == pResult;
  }

  bool has_query() {
    return pCurrentResult_ != NULL;
  }

  void con_check() {
    ConnStatusType status = PQstatus(pConn_);
    if (status == CONNECTION_OK) return;

    // Status was bad, so try resetting.
    PQreset(pConn_);
    status = PQstatus(pConn_);
    if (status == CONNECTION_OK) return;

    Rcpp::stop("Lost connection to database");
  }

  Rcpp::List info() {
    con_check();

    const char* dbnm = PQdb(pConn_);
    const char* host = PQhost(pConn_);
    const char* port = PQport(pConn_);
    int pver = PQprotocolVersion(pConn_);
    int sver = PQserverVersion(pConn_);

    return Rcpp::List::create(
      Rcpp::_["dbname"] = dbnm == NULL ? "" : std::string(dbnm),
      Rcpp::_["host"]   = host == NULL ? "" : std::string(host),
      Rcpp::_["port"]   = port == NULL ? "" : std::string(port),
      Rcpp::_["protocol_version"]   = pver,
      Rcpp::_["server_version"]     = sver
    );
  }

  // Returns a single CHRSXP
  SEXP escape_string(std::string x) {
    con_check();

    char* pq_escaped = PQescapeLiteral(pConn_, x.c_str(), x.length());
    SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
    PQfreemem(pq_escaped);

    return escaped;
  }

  // Returns a single CHRSXP
  SEXP escape_identifier(std::string x) {
    con_check();

    char* pq_escaped = PQescapeIdentifier(pConn_, x.c_str(), x.length());
    SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
    PQfreemem(pq_escaped);

    return escaped;
  }
};

#endif
