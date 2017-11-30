#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"


class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class PqRow;
typedef boost::shared_ptr<PqRow> PqRowPtr;

// DbResult --------------------------------------------------------------------
// There is no object analogous to DbResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  PGresult* pSpec_;
  PqRowPtr pNextRow_;
  std::vector<PGTypes> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, nparams_;
  bool bound_;

public:
  DbResult(DbConnectionPtr pConn, std::string sql);
  ~DbResult();

public:
  bool complete();
  bool active();

  void bind();
  void bind(List params);
  void bind_rows(List params);

  void fetch_row();
  void fetch_row_if_needed();
  List fetch(int n_max = -1);

  int n_rows_affected();
  int n_rows_fetched();

  List get_column_info();

private:
  List finish_df(List out) const;

  std::vector<std::string> get_column_names() const;
  std::vector<PGTypes> get_column_types() const;
};

#endif
