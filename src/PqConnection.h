#ifndef __RPOSTGRES_PQ_CONNECTION__
#define __RPOSTGRES_PQ_CONNECTION__

#include <Rcpp.h>
#include <libpq-fe.h>
#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "PqUtils.h"

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

      cancelQuery();
    }
    pCurrentResult_ = pResult;
  }

  void cancelQuery() {
    con_check();

    // Cancel running query
    PGcancel* cancel = PQgetCancel(pConn_);
    if (cancel == NULL) {
      Rcpp::warning("Failed to cancel running query");
      return;
    }

    char errbuf[256];
    if (!PQcancel(cancel, errbuf, 256)) {
      Rcpp::warning(errbuf);
    }

    PQfreeCancel(cancel);

    // Clear pending results
    PGresult* result;
    while((result = PQgetResult(pConn_)) != NULL) {
      PQclear(result);
    }
  }

  bool isCurrentResult(PqResult* pResult) {
    return pCurrentResult_ == pResult;
  }

  bool has_query() {
    return pCurrentResult_ != NULL;
  }

  void copy_data(std::string sql, Rcpp::List df) {
    int p = df.size();
    if (p == 0)
      return;

    PGresult* pInit = PQexec(pConn_, sql.c_str());
    if (PQresultStatus(pInit) != PGRES_COPY_IN) {
      PQclear(pInit);
      Rcpp::stop("Failed to initialise COPY");
    }
    PQclear(pInit);


    std::string buffer;
    int n = Rf_length(df[0]);
    // Sending row at-a-time is faster, presumable because it avoids copies
    // of buffer. Sending data asynchronously appears to be no faster.
    for (int i = 0; i < n; ++i) {
      buffer.clear();
      encodeRowInBuffer(df, i, buffer);

      if (PQputCopyData(pConn_, buffer.data(), buffer.size()) != 1) {
        Rcpp::stop(PQerrorMessage(pConn_));
      }
    }


    if (PQputCopyEnd(pConn_, NULL) != 1) {
      Rcpp::stop(PQerrorMessage(pConn_));
    }

    PGresult* pComplete = PQgetResult(pConn_);
    if (PQresultStatus(pComplete) != PGRES_COMMAND_OK) {
      PQclear(pComplete);
      Rcpp::stop(PQerrorMessage(pConn_));
    }
    PQclear(pComplete);
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
