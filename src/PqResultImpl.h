#ifndef RPOSTGRES_PQRESULTIMPL_H
#define RPOSTGRES_PQRESULTIMPL_H

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include "DbColumnDataType.h"
#include "PqResultSource.h"

class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

class PqResultImpl : boost::noncopyable, public PqResultSource {
  // Back pointer
  boost::shared_ptr<DbConnection> pConnPtr_;

  // Wrapped pointer
  PGconn* pConn_;

  // Expression
  const std::string sql_;
  const bool immediate_;

  // Wrapped pointer
  PGresult* pSpec_;

  // Cache
  struct _cache {
    bool initialized_;
    std::vector<std::string> names_;
    std::vector<Oid> oids_;
    std::vector<DATA_TYPE> types_;
    std::vector<bool> known_;
    size_t ncols_;
    int nparams_;

    _cache();
    void set(PGresult* spec);

    static std::vector<std::string> get_column_names(PGresult* spec);
    static DATA_TYPE get_column_type_from_oid(const Oid type);
    static std::vector<Oid> get_column_oids(PGresult* spec);
    static std::vector<DATA_TYPE> get_column_types(
      const std::vector<Oid>& oids,
      const std::vector<std::string>& names
    );
    static std::vector<bool> get_column_known(const std::vector<Oid>& oids);
  } cache;

  // State
  bool complete_;
  bool ready_;
  bool data_ready_;
  int nrows_;
  int rows_affected_;
  cpp11::list params_;
  int group_, groups_;
  PGresult* pRes_;

public:
  PqResultImpl(
    const DbConnectionPtr& pConn,
    const std::string& sql,
    bool immediate
  );
  ~PqResultImpl();

private:
  void prepare();
  void init(bool params_have_rows);

public:
  void close() {}  // FIXME
  bool complete() const;
  int n_rows_fetched();
  int n_rows_affected();
  void bind(const cpp11::list& params);
  cpp11::list fetch(const int n_max);

  cpp11::list get_column_info();

private:
  void set_params(const cpp11::list& params);
  bool bind_row();
  void after_bind(bool params_have_rows);

  cpp11::list fetch_rows(int n_max, int& n);
  void step();
  bool step_run();
  bool step_done();
  cpp11::list peek_first_row();

private:
  void conn_stop(const char* msg) const;

  void bind();

  void add_oids(cpp11::writable::list& data) const;

public:
  // PqResultSource
  PGresult* get_result();

private:
  bool wait_for_data();
};

#endif  // RPOSTGRES_PQRESULTIMPL_H
