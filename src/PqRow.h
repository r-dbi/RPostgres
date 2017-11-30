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

  bool has_data();
  int n_rows_affected();
  List get_exception_info();

  // Value accessors -----------------------------------------------------------
  bool is_null(int j);
  int get_int(int j);
  int64_t get_int64(int j);
  double get_double(int j);
  SEXP get_string(int j);
  SEXP get_raw(int j);
  double get_date(int j);
  double get_datetime(int j, bool use_local = true);
  double get_time(int j);
  int get_logical(int j);

  void set_list_value(SEXP x, int i, int j, const std::vector<DATA_TYPE>& types);
};

#endif
