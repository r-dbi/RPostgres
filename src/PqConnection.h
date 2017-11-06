#ifndef __RPOSTGRES_PQ_CONNECTION__
#define __RPOSTGRES_PQ_CONNECTION__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"

class PqResult;

// convenience typedef for shared_ptr to PqConnection
class PqConnection;
typedef boost::shared_ptr<PqConnection> PqConnectionPtr;

// PqConnection ----------------------------------------------------------------

class PqConnection : boost::noncopyable {
  PGconn* pConn_;
  PqResult* pCurrentResult_;

public:
  PqConnection(std::vector<std::string> keys, std::vector<std::string> values);
  virtual ~PqConnection();

public:
  PGconn* conn();

  void set_current_result(PqResult* pResult);
  void cancel_query();
  bool is_current_result(PqResult* pResult);
  bool has_query();

  void copy_data(std::string sql, List df);

  void check_connection();
  List info();

  SEXP escape_string(std::string x);
  SEXP escape_identifier(std::string x);
};

#endif
