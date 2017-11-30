#ifndef __RPOSTGRES_TYPES__
#define __RPOSTGRES_TYPES__

#include "pch.h"
#include "DbConnection.h"
#include "DbResult.h"

namespace Rcpp {

template<>
DbConnection* as(SEXP x);

template<>
DbResult* as(SEXP x);

}

#endif
