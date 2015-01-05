#include <Rcpp.h>
#include <libpq-fe.h>

inline Rcpp::IntegerVector int_fill_col(PGresult* res, int j, int n) {
  Rcpp::IntegerVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_INTEGER;
    } else {
      col[i] = atoi(PQgetvalue(res, i, j));
    }
  }

  return col;
}

inline Rcpp::NumericVector real_fill_col(PGresult* res, int j, int n) {
  Rcpp::NumericVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_REAL;
    } else {
      col[i] = atof(PQgetvalue(res, i, j));
    }
  }

  return col;
}

inline Rcpp::CharacterVector str_fill_col(PGresult* res, int j, int n) {
  Rcpp::CharacterVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_STRING;
    } else {
      char* val = PQgetvalue(res, i, j);
      col[i] = Rf_mkCharCE(val, CE_UTF8);
    }
  }

  return col;
}

inline Rcpp::LogicalVector lgl_fill_col(PGresult* res, int j, int n) {
  Rcpp::LogicalVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_LOGICAL;
    } else {
      col[i] = (strcmp(PQgetvalue(res, i, j), "t") == 0);
    }
  }

  return col;
}

class PqConnection {
  PGconn* pConn_;
  PGresult* pRes_;
  int rows_, fetched_rows_;

public:
  PqConnection(std::vector<std::string> keys, std::vector<std::string> values) {
    pConn_ = NULL;
    pRes_ = NULL;

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

  ~PqConnection() {
    disconnect();
  };

  void disconnect() {
    clear_result();
    if (pConn_ != NULL) {
      PQfinish(pConn_);
      pConn_ = NULL;
    }
  }

  // Connections ---------------------------------------------------------------
  void con_check() {
    if (pConn_ == NULL)
      Rcpp::stop("Connection has been closed");

    ConnStatusType status = PQstatus(pConn_);
    if (status == CONNECTION_OK) return;

    // Status was bad, so try resetting.
    PQreset(pConn_);
    status = PQstatus(pConn_);
    if (status == CONNECTION_OK) return;

    Rcpp::stop("Lost connection to database");
  }

  Rcpp::List con_info() {
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


  // Results -------------------------------------------------------------------
  void exec(std::string query) {
    con_check();

    if (pRes_ != NULL) {
      PQclear(pRes_);
      fetched_rows_ = 0;
      rows_ = 0;
    }

    pRes_ = PQexecParams(pConn_, query.c_str(), 0, NULL, NULL, NULL, NULL, 0);
    pRes_check();

    fetched_rows_ = 0;
    rows_ = PQntuples(pRes_);
  }

  void pRes_check() {
    if (pRes_ == NULL)
      Rcpp::stop("No results");

    if (PQresultStatus(pRes_) == PGRES_FATAL_ERROR) {
      Rcpp::stop(PQerrorMessage(pConn_));
    }
  }

  void clear_result() {
    if (pRes_ != NULL) {
      PQclear(pRes_);
      pRes_ = NULL;
    }
  }

  bool is_complete() {
    return rows_ == fetched_rows_;
  }

  Rcpp::List fetch() {
    pRes_check();

    int p = PQnfields(pRes_);
    Rcpp::List cols(p);
    Rcpp::CharacterVector names(p);

    for (int j = 0; j < p; ++j) {
      Oid type = PQftype(pRes_, j);
      std::string name(PQfname(pRes_, j));
      SEXP col;

      // These come from
      // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
      switch(type) {
      case 20: // BIGINT
      case 21: // SMALLINT
      case 23: // INTEGER
      case 26: // OID
        col = int_fill_col(pRes_, j, rows_);
        break;

      case 1700: // DECIMAL
      case 701: // FLOAT8
      case 700: // FLOAT
      case 790: // MONEY
        col = real_fill_col(pRes_, j, rows_);
        break;

      case 18: // CHAR
      case 19: // NAME
      case 25: // TEXT
      case 1042: // CHAR
      case 1043: // VARCHAR
      case 1082: // DATE
      case 1083: // TIME
      case 1114: // TIMESTAMP
      case 1184: // TIMESTAMPTZOID
      case 1186: // INTERVAL
      case 1266: // TIMETZOID
        col = str_fill_col(pRes_, j, rows_);
        break;

      case 16: // BOOL
        col = lgl_fill_col(pRes_, j, rows_);
        break;

      case 17: // BYTEA
      case 2278: // NULL
      default:
        col = str_fill_col(pRes_, j, rows_);

        std::stringstream err;
        err << "Unknown field type (" << type << ") in column " << name;
        Rcpp::Function warning("warning");
        warning(err.str());
      }

      cols[j] = col;
      names[j] = name;
    }

    fetched_rows_ = rows_;

    cols.names() = names;
    cols.attr("class") = "data.frame";
    cols.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -rows_);
    return cols;
  }

  Rcpp::List exception_info() {
    if (pRes_ == NULL)
      Rcpp::stop("No results");

    const char* sev = PQresultErrorField(pRes_, PG_DIAG_SEVERITY);
    const char* msg = PQresultErrorField(pRes_, PG_DIAG_MESSAGE_PRIMARY);
    const char* det = PQresultErrorField(pRes_, PG_DIAG_MESSAGE_DETAIL);
    const char* hnt = PQresultErrorField(pRes_, PG_DIAG_MESSAGE_HINT);

    return Rcpp::List::create(
      Rcpp::_["severity"] = sev == NULL ? "" : std::string(sev),
      Rcpp::_["message"]  = msg == NULL ? "" : std::string(msg),
      Rcpp::_["detail"]   = det == NULL ? "" : std::string(det),
      Rcpp::_["hint"]     = hnt == NULL ? "" : std::string(hnt)
    );
  }

  int rows_affected() {
    pRes_check();
    if (PQresultStatus(pRes_) != PGRES_COMMAND_OK)
      Rcpp::stop("Not a data modifying query");

    return atoi(PQcmdTuples(pRes_));
  }

  // Prevent copying because of shared resource
private:
  PqConnection( PqConnection const& );
  PqConnection operator=( PqConnection const& );

};
