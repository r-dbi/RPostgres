#include "pch.h"
#include "PqResult.h"
#include "PqResultPrep.h"
#include "PqResultSimple.h"



// Construction ////////////////////////////////////////////////////////////////

PqResult::PqResult(const DbConnectionPtr& pConn, const std::string& sql, const bool immediate) :
  DbResult(pConn)
{
  if (immediate) {
    impl.reset(new PqResultSimple(pConn, sql));
  }
  else {
    impl.reset(new PqResultPrep(pConn, sql));
  }
}


// Publics /////////////////////////////////////////////////////////////////////

DbResult* PqResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql, const bool immediate) {
  return new PqResult(con, sql, immediate);
}


// Privates ///////////////////////////////////////////////////////////////////
