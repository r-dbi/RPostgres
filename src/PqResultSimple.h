#ifndef RPOSTGRES_PQRESULTSIMPLE_H
#define RPOSTGRES_PQRESULTSIMPLE_H

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "DbColumnDataType.h"
#include "PqResultImpl.h"
#include "PqResultSource.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class PqResultSimple : boost::noncopyable, public PqResultImpl, public PqResultSource {
  // Back pointer
  boost::shared_ptr<DbConnection> pConnPtr_;

  // Wrapped pointer
  PGconn* pConn_;
  PGresult* pRes_;

  // Cache
  struct _cache {
    const std::vector<std::string> names_;
    const std::vector<Oid> oids_;
    const std::vector<DATA_TYPE> types_;
    const std::vector<bool> known_;
    const size_t ncols_;

    _cache(PGresult* spec);

    static std::vector<std::string> get_column_names(PGresult* spec);
    static DATA_TYPE get_column_type_from_oid(const Oid type);
    static std::vector<Oid> get_column_oids(PGresult* spec);
    static std::vector<DATA_TYPE> get_column_types(const std::vector<Oid>& oids, const std::vector<std::string>& names);
    static std::vector<bool> get_column_known(const std::vector<Oid>& oids);
  } cache;

  // State
  bool complete_;
  bool ready_;
  bool data_ready_;
  int nrows_;
  int rows_affected_;
  List params_;

public:
  PqResultSimple(const DbConnectionPtr& pConn, const std::string& sql);
  ~PqResultSimple();

private:
  static PGresult* prepare(PGconn* conn, const std::string& sql);
  void init(bool params_have_rows);

public:
  // PgResultImpl
  virtual void close();

  virtual void bind(const List& params);

  virtual List get_column_info();

  virtual List fetch(int n_max = -1);

  virtual int n_rows_affected();
  virtual int n_rows_fetched();
  virtual bool complete();

private:
  List fetch_rows(int n_max, int& n);
  void step();
  void step_done();
  List peek_first_row();

private:
  void conn_stop(const char* msg) const;

  void add_oids(List& data) const;

public:
  // PqResultSource
  PGresult* get_result();

private:
  void wait_for_data();
};

#endif //RPOSTGRES_PQRESULTIMPL_H
