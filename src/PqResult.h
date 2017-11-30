#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"


class PqConnection;
typedef boost::shared_ptr<PqConnection> PqConnectionPtr;

class PqRow;
typedef boost::shared_ptr<PqRow> PqRowPtr;

// PqResult --------------------------------------------------------------------
// There is no object analogous to PqResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResult : boost::noncopyable {
  PqConnectionPtr pConn_;
  PGresult* pSpec_;
  PqRowPtr pNextRow_;
  std::vector<PGTypes> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, nparams_;
  bool bound_;

public:
  PqResult(PqConnectionPtr pConn, std::string sql);
  ~PqResult();

public:
  void bind();
  void bind(List params);
  void bind_rows(List params);

  bool active();

  void fetch_row();
  void fetch_row_if_needed();
  List fetch(int n_max = -1);

  int n_rows_affected();
  int n_rows_fetched();
  bool is_complete();

  List get_column_info();

private:
  List finish_df(List out) const;

  std::vector<std::string> get_column_names() const;
  std::vector<PGTypes> get_column_types() const;
};

#endif
