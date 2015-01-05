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
  }

  void exec(std::string query) {
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

  ~PqConnection() {
    if (conn != NULL) {
      PQfinish(conn);
    }
    if (res != NULL) {
      PQclear(res);
    }
  };

};
