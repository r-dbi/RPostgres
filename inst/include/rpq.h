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
  PGconn* conn;
  PGresult* res;
  int rows, fetched_rows;

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

  ~PqConnection() {
    disconnect();
  };

  void disconnect() {
    clear_result();
    if (conn != NULL) {
      PQfinish(conn);
      conn = NULL;
    }
  }

  // Connections ---------------------------------------------------------------
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


  // Results -------------------------------------------------------------------
  void exec(std::string query) {
    con_check();

    if (res != NULL) {
      PQclear(res);
      fetched_rows = 0;
      rows = 0;
    }

    res = PQexecParams(conn, query.c_str(), 0, NULL, NULL, NULL, NULL, 0);
    res_check();

    fetched_rows = 0;
    rows = PQntuples(res);
  }

  void res_check() {
    if (res == NULL)
      Rcpp::stop("No results");

    if (PQresultStatus(res) == PGRES_FATAL_ERROR) {
      Rcpp::stop(PQerrorMessage(conn));
    }
  }

  void clear_result() {
    if (res != NULL) {
      PQclear(res);
      res = NULL;
    }
  }

  bool is_complete() {
    return rows == fetched_rows;
  }

  Rcpp::List fetch() {
    res_check();

    int p = PQnfields(res);
    Rcpp::List cols(p);
    Rcpp::CharacterVector names(p);

    for (int j = 0; j < p; ++j) {
      Oid type = PQftype(res, j);
      std::string name(PQfname(res, j));
      SEXP col;

      // These come from
      // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
      switch(type) {
      case 20: // BIGINT
      case 21: // SMALLINT
      case 23: // INTEGER
      case 26: // OID
        col = int_fill_col(res, j, rows);
        break;

      case 1700: // DECIMAL
      case 701: // FLOAT8
      case 700: // FLOAT
      case 790: // MONEY
        col = real_fill_col(res, j, rows);
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
        col = str_fill_col(res, j, rows);
        break;

      case 16: // BOOL
        col = lgl_fill_col(res, j, rows);
        break;

      case 17: // BYTEA
      case 2278: // NULL
      default:
        col = str_fill_col(res, j, rows);

        std::stringstream err;
        err << "Unknown field type (" << type << ") in column " << name;
        Rcpp::Function warning("warning");
        warning(err.str());
      }

      cols[j] = col;
      names[j] = name;
    }

    fetched_rows = rows;

    cols.names() = names;
    cols.attr("class") = "data.frame";
    cols.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -rows);
    return cols;
  }

  Rcpp::List exception_info() {
    if (res == NULL)
      Rcpp::stop("No results");

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
    res_check();
    if (PQresultStatus(res) != PGRES_COMMAND_OK)
      Rcpp::stop("Not a data modifying query");

    return atoi(PQcmdTuples(res));
  }
};
