#ifndef __RPOSTGRES_PQ_ROW__
#define __RPOSTGRES_PQ_ROW__

#include <boost/noncopyable.hpp>

#include "PqUtils.h"

// PqRow -----------------------------------------------------------------------
// A single row of results from PostgreSQL
class PqRow : boost::noncopyable {
  PGresult* pRes_;

public:
  PqRow(PGconn* conn);
  ~PqRow();

public:
  ExecStatusType status();

  bool hasData();
  int rowsAffected();
  Rcpp::List exceptionInfo();

  // Value accessors -----------------------------------------------------------
  bool valueNull(int j);
  int valueInt(int j);
  double valueDouble(int j);
  SEXP valueString(int j);
  SEXP valueRaw(int j);
  double valueDate(int j);
  double valueDatetime(int j, bool use_local = true);
  double valueTime(int j);
  int valueLogical(int j);

  void setListValue(SEXP x, int i, int j, const std::vector<PGTypes>& types);
};

#endif
