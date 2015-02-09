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

  PqRow(PGconn *conn): pRes_(NULL) {
    if (conn != NULL)
      pRes_ = PQgetResult(conn);
  }

  // Query is complete when PQgetResult returns NULL
  bool is_complete() {
    return pRes_ == NULL;
  }

  ~PqRow() {
    try {
      PQclear(pRes_);
    } catch(...) {}
  }

  Rcpp::List exception_info() {
    if (is_complete())
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
};

#endif
