#ifndef __RPOSTGRES_PQ_CONNECTION__
#define __RPOSTGRES_PQ_CONNECTION__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"

class DbResult;

// convenience typedef for shared_ptr to DbConnection
class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

// DbConnection ----------------------------------------------------------------

class DbConnection : boost::noncopyable {
  PGconn* pConn_;
  DbResult* pCurrentResult_;
  bool transacting_;

public:
  DbConnection(std::vector<std::string> keys, std::vector<std::string> values);
  virtual ~DbConnection();

public:
  PGconn* conn();

  void set_current_result(DbResult* pResult);
  bool is_current_result(DbResult* pResult);
  bool has_query();

  void copy_data(std::string sql, List df);

  void check_connection();
  List info();

  SEXP escape_string(std::string x);
  SEXP escape_identifier(std::string x);

  bool is_transacting() const;
  void set_transacting(bool transacting);

  void conn_stop(const char* msg);

  void cleanup_query();

private:
  void cancel_query();
  void finish_query() const;
};

#endif
