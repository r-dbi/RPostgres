#ifndef __RPOSTGRES_TYPES__
#define __RPOSTGRES_TYPES__

#include "pch.h"
#include "PqConnection.h"
#include "PqResult.h"

namespace Rcpp {

template<>
PqResult* as(SEXP x);

}

#endif
