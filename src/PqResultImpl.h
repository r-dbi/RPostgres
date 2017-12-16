#ifndef RPOSTGRES_PQRESULTIMPL_H
#define RPOSTGRES_PQRESULTIMPL_H

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "DbColumnDataType.h"
#include "PqResultSource.h"

class DbResult;

class PqResultImpl : boost::noncopyable, public PqResultSource {
  // Back pointer for query cancellation
  DbResult* res;

  // Wrapped pointer
  PGconn* pConn_;
  PGresult* pSpec_;

  // Cache
  struct _cache {
    const std::vector<std::string> names_;
    const std::vector<DATA_TYPE> types_;
    const size_t ncols_;
    const int nparams_;

    _cache(PGresult* spec);

    static std::vector<std::string> get_column_names(PGresult* spec);
    static std::vector<DATA_TYPE> get_column_types(PGresult* spec);
  } cache;

  // State
  bool complete_;
  bool ready_;
  int nrows_;
  int rows_affected_;
  List params_;
  int group_, groups_;
  PGresult* pRes_;

public:
  PqResultImpl(DbResult* pRes, PGconn* pConn, const std::string& sql);
  ~PqResultImpl();

private:
  static PGresult* prepare(PGconn* conn, const std::string& sql);
  void init(bool params_have_rows);

public:
  bool complete() const;
  int n_rows_fetched();
  int n_rows_affected();
  void bind(const List& params);
  List fetch(const int n_max);

  List get_column_info();

private:
  void set_params(const List& params);
  bool bind_row();
  void after_bind(bool params_have_rows);

  List fetch_rows(int n_max, int& n);
  void step();
  bool step_run();
  bool step_done();
  List peek_first_row();

private:
  void conn_stop(const char* msg) const;

  void bind();

public:
  // PqResultSource
  PGresult* get_result();
};

#endif //RPOSTGRES_PQRESULTIMPL_H
