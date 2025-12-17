#include "pch.h"
#include <type_traits>

#ifndef __RPOSTGRES_TYPES__
#define __RPOSTGRES_TYPES__

#include "DbConnection.h"
#include "DbResult.h"

namespace cpp4r {

template <typename T>
std::enable_if_t<std::is_same<std::decay_t<T>, DbConnection*>::value, std::decay_t<T>> as_cpp(SEXP from) {
  DbConnectionPtr* connection = (DbConnectionPtr*)(R_ExternalPtrAddr(from));
  if (!connection)
    cpp4r::stop("Invalid connection");
  return connection->get();
}

template <typename T>
std::enable_if_t<std::is_same<std::decay_t<T>, DbResult*>::value, std::decay_t<T>> as_cpp(SEXP from) {
  DbResult* result = (DbResult*)(R_ExternalPtrAddr(from));
  if (!result)
    cpp4r::stop("Invalid result set");
  return result;
}

}

#endif
