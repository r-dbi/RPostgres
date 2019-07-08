#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include "DbResult.h"

class PqResult : public DbResult {
public:
  PqResult(const DbConnectionPtr& pConn, const std::string& sql);

public:
  static DbResult* create_and_send_query(const DbConnectionPtr& con, const std::string& sql);
};

#endif // __RPOSTGRES_PQ_RESULT__
