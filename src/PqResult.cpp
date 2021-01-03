#include "pch.h"
#include "PqResult.h"
#include "DbResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

PqResult::PqResult(const DbConnectionPtr& pConn, const std::string& sql, const int utcoffset) :
  DbResult(pConn)
{
  impl.reset(new DbResultImpl(pConn, sql, utcoffset));
}


// Publics /////////////////////////////////////////////////////////////////////

DbResult* PqResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql, const int utcoffset) {
  return new PqResult(con, sql, utcoffset);
}


// Privates ///////////////////////////////////////////////////////////////////
