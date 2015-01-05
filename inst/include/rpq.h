#include <Rcpp.h>
#include <libpq-fe.h>

class PqConnection {
  PGconn* conn;
  PGresult* res;

public:
  PqConnection(std::vector<std::string> keys_, std::vector<std::string> values_) {
    conn = NULL;
    res = NULL;

    int n = keys_.size();
    std::vector<const char*> keys(n + 1), values(n + 1);

    for (int i = 0; i < n; ++i) {
      keys[i] = keys_[i].c_str();
      values[i] = values_[i].c_str();
    }
    keys[n] = NULL;
    values[n] = NULL;

    conn = PQconnectdbParams(&keys[0], &values[0], false);

    if (PQstatus(conn) != CONNECTION_OK) {
      std::string err = PQerrorMessage(conn);
      PQfinish(conn);
      Rcpp::stop(err);
    }

    PQsetClientEncoding(conn, "UTF-8");
  }

  void exec(std::string query) {
    con_check();

    if (res != NULL) {
      PQclear(res);
    }

    res = PQexecParams(conn, query.c_str(), 0, NULL, NULL, NULL, NULL, 0);

    if (PQresultStatus(res) == PGRES_FATAL_ERROR) {
      Rcpp::stop(PQerrorMessage(conn));
    }
  }

  Rcpp::List exception_details() {
    if (res == NULL) {
      Rcpp::stop("No query executed on this connection");
    }

    const char* sev = PQresultErrorField(res, PG_DIAG_SEVERITY);
    const char* msg = PQresultErrorField(res, PG_DIAG_MESSAGE_PRIMARY);
    const char* det = PQresultErrorField(res, PG_DIAG_MESSAGE_DETAIL);
    const char* hnt = PQresultErrorField(res, PG_DIAG_MESSAGE_HINT);

    return Rcpp::List::create(
      Rcpp::_["severity"] = sev == NULL ? "" : std::string(sev),
      Rcpp::_["message"]  = msg == NULL ? "" : std::string(msg),
      Rcpp::_["detail"]   = det == NULL ? "" : std::string(det),
      Rcpp::_["hint"]     = hnt == NULL ? "" : std::string(hnt)
    );
  }

  Rcpp::List con_info() {
    con_check();

    const char* dbnm = PQdb(conn);
    const char* host = PQhost(conn);
    const char* port = PQport(conn);
    int pver = PQprotocolVersion(conn);
    int sver = PQserverVersion(conn);

    return Rcpp::List::create(
      Rcpp::_["dbname"] = dbnm == NULL ? "" : std::string(dbnm),
      Rcpp::_["host"]   = host == NULL ? "" : std::string(host),
      Rcpp::_["port"]   = port == NULL ? "" : std::string(port),
      Rcpp::_["protocol_version"]   = pver,
      Rcpp::_["server_version"]     = sver
    );
  }

  int rows_affected() {
    if (!is_valid_res()) Rcpp::stop("No query exectuted");
    if (PQresultStatus(res) != PGRES_COMMAND_OK) Rcpp::stop("Not a DDL query");

    return atoi(PQcmdTuples(res));
  }

  bool is_valid_conn() {
    return conn != NULL;
  }

  bool is_valid_res() {
    return res != NULL;
  }

  void disconnect() {
    if (res != NULL) {
      PQclear(res);
      res = NULL;
    }
    if (conn != NULL) {
      PQfinish(conn);
      conn = NULL;
    }
  }

  // Returns a single CHRSXP
  SEXP escape_string(std::string x) {
    con_check();

    char* escaped_ = PQescapeLiteral(conn, x.c_str(), x.length());
    SEXP escaped = Rf_mkCharCE(escaped_, CE_UTF8);
    PQfreemem(escaped_);

    return escaped;
  }

  // Returns a single CHRSXP
  SEXP escape_identifier(std::string x) {
    con_check();

    char* escaped_ = PQescapeIdentifier(conn, x.c_str(), x.length());
    SEXP escaped = Rf_mkCharCE(escaped_, CE_UTF8);
    PQfreemem(escaped_);

    return escaped;
  }

  void con_check() {
    if (conn == NULL)
      Rcpp::stop("Connection has been closed");

    ConnStatusType status = PQstatus(conn);
    if (status == CONNECTION_OK) return;

    // Status was bad, so try resetting.
    PQreset(conn);
    status = PQstatus(conn);
    if (status == CONNECTION_OK) return;

    Rcpp::stop("Lost connection to database");
  }

  ~PqConnection() {
    disconnect();
  };

};
