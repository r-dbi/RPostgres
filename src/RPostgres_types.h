#ifndef __RPOSTGRES_TYPES__
#define __RPOSTGRES_TYPES__

#include "pch.h"
#include "DbConnection.h"
#include "DbResult.h"

namespace Rcpp {

template<>
PqConnection* as(SEXP x);

template<>
PqResult* as(SEXP x);

}

#endif
