#ifndef RPOSTGRES_PQRESULTIMPL_H
#define RPOSTGRES_PQRESULTIMPL_H

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"

class PqRow;
typedef boost::shared_ptr<PqRow> PqRowPtr;

class PqResultImpl : boost::noncopyable {
  // Wrapped pointer
  PGconn* pConn_;
  PGresult* pSpec_;

  // Cache
  struct _cache {
    const std::vector<std::string> names_;
    const std::vector<PGTypes> types_;
    const int ncols_;
    const int nparams_;

    _cache(PGresult* spec);

    static std::vector<std::string> get_column_names(PGresult* spec);
    static std::vector<PGTypes> get_column_types(PGresult* spec);
  } cache;

  // State
  PqRowPtr pNextRow_;
  bool ready_;
  int nrows_;

public:
  PqResultImpl(PGconn* pConn, const std::string& sql);
  ~PqResultImpl();

private:
  static PGresult* prepare(PGconn* conn, const std::string& sql);

public:
  bool complete();
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const List& params);
  List fetch(const int n_max);

  List get_column_info();

private:
  void bind();

  void fetch_row();
  void fetch_row_if_needed();

private:
  List finish_df(List out) const;


  void conn_stop(const char* msg) const;
};

#endif //RPOSTGRES_PQRESULTIMPL_H
