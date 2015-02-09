#ifndef __RPOSTGRES_PQ_ROW__
#define __RPOSTGRES_PQ_ROW__

#include <Rcpp.h>
#include <libpq-fe.h>
#include <boost/noncopyable.hpp>

// PqRow -----------------------------------------------------------------------
// A single row of results from PostgreSQL
class PqRow : boost::noncopyable {
  PGresult* pRes_;

public:

  PqRow(PGconn* conn) {
    if (conn == NULL)
      return;
    pRes_ = PQgetResult(conn);


    if (pRes_ != NULL && status() == PGRES_TUPLES_OK) {
      // We're done, but we need to call PQgetResult until it returns NULL
      while(pRes_ != NULL) {
        PQclear(pRes_);
        pRes_ = PQgetResult(conn);
      }
    }
  }

  // Query is complete when PQgetResult returns NULL
  bool complete() {
    return pRes_ == NULL;
  }

  ExecStatusType status() {
    return PQresultStatus(pRes_);
  }

  ~PqRow() {
    try {
      PQclear(pRes_);
    } catch(...) {}
  }

  int ncols() {
    return PQnfields(pRes_);
  }

  std::vector<std::string> column_names() {
    std::vector<std::string> names;
    names.reserve(ncols());

    for (int i = 0; i < ncols(); ++i) {
      names.push_back(std::string(PQfname(pRes_, i)));
    }

    return names;
  }

  std::vector<SEXPTYPE> column_types() {
    std::vector<SEXPTYPE> types;
    types.reserve(ncols());

    for (int i = 0; i < ncols(); ++i) {
      Oid type = PQftype(pRes_, i);
      // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
      switch(type) {
      case 20: // BIGINT
      case 21: // SMALLINT
      case 23: // INTEGER
      case 26: // OID
        types.push_back(INTSXP);
        break;

      case 1700: // DECIMAL
      case 701: // FLOAT8
      case 700: // FLOAT
      case 790: // MONEY
        types.push_back(REALSXP);
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
        types.push_back(STRSXP);
        break;

      case 16: // BOOL
        types.push_back(LGLSXP);
        break;

      case 17: // BYTEA
      case 2278: // NULL
        types.push_back(VECSXP);
        break;

      default:
        types.push_back(STRSXP);
        Rcpp::warning("Unknown field type (%s) in column %i", type, i);
      }
    }

    return types;
  }

  int rowsAffected() {
    return atoi(PQcmdTuples(pRes_));
  }

  Rcpp::List exception_info() {
    if (complete())
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

  // Value accessors -----------------------------------------------------------
  bool value_null(int j) {
    return PQgetisnull(pRes_, 0, j);
  }

  int value_int(int j) {
    return value_null(j) ? NA_INTEGER : atoi(PQgetvalue(pRes_, 0, j));
  }

  double value_double(double j) {
    return value_null(j) ? NA_REAL : atof(PQgetvalue(pRes_, 0, j));
  }

  SEXP value_string(int j) {
    if (value_null(j))
      return NA_STRING;

    char* val = PQgetvalue(pRes_, 0, j);
    return Rf_mkCharCE(val, CE_UTF8);
  }

  SEXP value_raw(int j) {
    int size = PQgetlength(pRes_, 0, j);
    const void* blob = PQgetvalue(pRes_, 0, j);

    SEXP bytes = Rf_allocVector(RAWSXP, size);
    memcpy(RAW(bytes), blob, size);

    return bytes;
  }

  int value_logical(int j) {
    return value_null(j) ? NA_LOGICAL :
      (strcmp(PQgetvalue(pRes_, 0, j), "t") == 0);
  }

  void set_list_value(SEXP x, int i, int j) {
    switch(TYPEOF(x)) {
    case LGLSXP:
      LOGICAL(x)[i] = value_logical(j);
      break;
    case INTSXP:
      INTEGER(x)[i] = value_int(j);
      break;
    case REALSXP:
      REAL(x)[i] = value_double(j);
      break;
    case STRSXP:
      SET_STRING_ELT(x, i, value_string(j));
      break;
    case VECSXP:
      SET_VECTOR_ELT(x, i, value_raw(j));
      break;
    }
  }

};

#endif
