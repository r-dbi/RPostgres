#include "pch.h"

#ifndef __RPOSTGRES_TYPES__
#define __RPOSTGRES_TYPES__

#include "DbConnection.h"
#include "DbResult.h"

namespace cpp11 {

template <typename T>
enable_if_t<std::is_same<decay_t<T>, DbConnection*>::value, decay_t<T>> as_cpp(SEXP from) {
  DbConnectionPtr* connection = (DbConnectionPtr*)(R_ExternalPtrAddr(from));
  if (!connection)
    stop("Invalid connection");
  return connection->get();
}

template <typename T>
enable_if_t<std::is_same<decay_t<T>, DbResult*>::value, decay_t<T>> as_cpp(SEXP from) {
  DbResult* result = (DbResult*)(R_ExternalPtrAddr(from));
  if (!result)
    stop("Invalid result set");
  return result;
}

}

#endif
