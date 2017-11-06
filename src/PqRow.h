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
  bool inline valueNull(int j) {
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

  double valueDate(int j) {
    if (valueNull(j)) {
      return NA_REAL;
    }
    char* val = PQgetvalue(pRes_, 0, j);
    struct tm date = { 0 };
    date.tm_isdst = -1;
    date.tm_year = *val - 0x30;
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30);
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30);
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30) - 1900;
    val++;
    date.tm_mon = 10 *(*(++val)-0x30);
    date.tm_mon += (*(++val)-0x30) -1;
    val++;
    date.tm_mday = (*(++val)-0x30) * 10;
    date.tm_mday += (*(++val)-0x30);
    return timegm(&date)/(24*60*60);
  }

  double valueDatetime(int j, bool use_local = true) {
    if (valueNull(j)) {
      return NA_REAL;
    }
    char* val = PQgetvalue(pRes_, 0, j);
    char* end;
    struct tm date;
    date.tm_isdst = -1;
    date.tm_year = *val - 0x30;
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30);
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30);
    date.tm_year *= 10;
    date.tm_year += (*(++val)-0x30) - 1900;
    val++;
    date.tm_mon = (*(++val)-0x30)*10;
    date.tm_mon += (*(++val)-0x30)-1;
    val++;
    date.tm_mday = (*(++val)-0x30)*10;
    date.tm_mday += (*(++val)-0x30);
    val++;
    date.tm_hour = (*(++val)-0x30)*10;
    date.tm_hour += (*(++val)-0x30);
    val++;
    date.tm_min = (*(++val)-0x30)*10;
    date.tm_min += (*(++val)-0x30);
    val++;
    double sec = strtod(++val, &end);
    date.tm_sec = sec;
    if (use_local) {
      return mktime(&date) + (sec - date.tm_sec);
    } else {
      return timegm(&date) + (sec - date.tm_sec);
    }
  }

  double valueTime(int j) {
    if (valueNull(j)) {
      return NA_REAL;
    }
    char* val = PQgetvalue(pRes_, 0, j);
    int hour = (*val-0x30)*10;
    hour += (*(++val)-0x30);
    val++;
    int min = (*(++val)-0x30)*10;
    min += (*(++val)-0x30);
    val++;
    double sec = strtod(++val, NULL);
    return static_cast<double>(hour * 3600 + min * 60) + sec;
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
    case PGDate:
      REAL(x)[i] = valueDate(j);
      break;
    case PGDatetimeTZ:
      REAL(x)[i] = valueDatetime(j, false);
      break;
    case PGDatetime:
      REAL(x)[i] = valueDatetime(j, true);
      break;
    case PGTime:
      REAL(x)[i] = valueTime(j);
    }
  }

};

#endif
