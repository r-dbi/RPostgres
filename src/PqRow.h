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

    // We're done, but we need to call PQgetResult until it returns NULL
    if (status() == PGRES_TUPLES_OK) {
      PGresult* next = PQgetResult(conn);
      while(next != NULL) {
        PQclear(next);
        next = PQgetResult(conn);
      }
    }

    if (pRes_ == NULL) {
      PQclear(pRes_);
      Rcpp::stop("No active query");
    }

    if (PQresultStatus(pRes_) == PGRES_FATAL_ERROR) {
      PQclear(pRes_);
      Rcpp::stop(PQerrorMessage(conn));
    }
  }

  ExecStatusType status() {
    return PQresultStatus(pRes_);
  }

  bool hasData() {
    return status() == PGRES_SINGLE_TUPLE;
  }

  ~PqRow() {
    try {
      PQclear(pRes_);
    } catch(...) {}
  }

  int rowsAffected() {
    return atoi(PQcmdTuples(pRes_));
  }

  Rcpp::List exceptionInfo() {
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
  bool valueNull(int j) {
    return PQgetisnull(pRes_, 0, j);
  }

  int valueInt(int j) {
    return valueNull(j) ? NA_INTEGER : atoi(PQgetvalue(pRes_, 0, j));
  }

  double valueDouble(int j) {
    return valueNull(j) ? NA_REAL : atof(PQgetvalue(pRes_, 0, j));
  }

  SEXP valueString(int j) {
    if (valueNull(j))
      return NA_STRING;

    char* val = PQgetvalue(pRes_, 0, j);
    return Rf_mkCharCE(val, CE_UTF8);
  }

  SEXP valueRaw(int j) {
    int size = PQgetlength(pRes_, 0, j);
    const void* blob = PQgetvalue(pRes_, 0, j);

    SEXP bytes = Rf_allocVector(RAWSXP, size);
    memcpy(RAW(bytes), blob, size);

    return bytes;
  }

  int valueLogical(int j) {
    return valueNull(j) ? NA_LOGICAL :
      (strcmp(PQgetvalue(pRes_, 0, j), "t") == 0);
  }

  void setListValue(SEXP x, int i, int j, const std::vector<PGTypes>& types) {
    switch(types[j]) {
    case PGLogical:
      LOGICAL(x)[i] = valueLogical(j);
      break;
    case PGInt:
      INTEGER(x)[i] = valueInt(j);
      break;
    case PGReal:
      REAL(x)[i] = valueDouble(j);
      break;
   case PGVector:
      SET_VECTOR_ELT(x, i, valueRaw(j));
      break;
   case PGString:
      SET_STRING_ELT(x, i, valueString(j));
      break;
    }
  }

};

#endif
