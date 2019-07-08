#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include "DbResult.h"

// There is no object analogous to DbResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResult : public DbResult {
public:
  PqResult(const DbConnectionPtr& pConn, const std::string& sql);

public:
  static DbResult* create_and_send_query(const DbConnectionPtr& con, const std::string& sql);
};

#endif // __RPOSTGRES_PQ_RESULT__
