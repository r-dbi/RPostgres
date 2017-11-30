#ifndef RPOSTGRES_PQRESULTIMPL_H
#define RPOSTGRES_PQRESULTIMPL_H

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"

class PqRow;
typedef boost::shared_ptr<PqRow> PqRowPtr;

class PqResultImpl : boost::noncopyable {
  PGconn* pConn_;
  PGresult* pSpec_;
  PqRowPtr pNextRow_;
  std::vector<PGTypes> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, nparams_;
  bool bound_;

public:
  PqResultImpl(PGconn* pConn, const std::string& sql);
  ~PqResultImpl();

public:
  bool complete();
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const List& params);
  List fetch(int n_max = -1);

  List get_column_info();

private:
  void bind();
  void bind_rows(List params);

  void fetch_row();
  void fetch_row_if_needed();

private:
  List finish_df(List out) const;

  std::vector<std::string> get_column_names() const;
  std::vector<PGTypes> get_column_types() const;

  void conn_stop(const char* msg) const;
};

#endif //RPOSTGRES_PQRESULTIMPL_H
