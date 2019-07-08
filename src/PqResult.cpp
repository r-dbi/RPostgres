#include "pch.h"
#include "PqResult.h"



// Construction ////////////////////////////////////////////////////////////////

PqResult::PqResult(const DbConnectionPtr& pConn, const std::string& sql) :
  DbResult(pConn, sql)
{
}


// Publics /////////////////////////////////////////////////////////////////////

DbResult* PqResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql) {
  return new PqResult(con, sql);
}


// Privates ///////////////////////////////////////////////////////////////////
