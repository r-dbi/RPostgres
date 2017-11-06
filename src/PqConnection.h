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

  void setCurrentResult(PqResult* pResult);
  void cancelQuery();
  bool isCurrentResult(PqResult* pResult);
  bool hasQuery();

  void copyData(std::string sql, List df);

  void conCheck();
  List info();

  SEXP escapeString(std::string x);
  SEXP escapeIdentifier(std::string x);
};

#endif
