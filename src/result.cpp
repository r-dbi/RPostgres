#include "pch.h"
#include "RPostgres_types.h"


// [[Rcpp::export]]
XPtr<PqResult> result_create(XPtr<PqConnectionPtr> con, std::string sql) {
  PqResult* res = new PqResult(*con, sql);
  return XPtr<PqResult>(res, true);
}

// [[Rcpp::export]]
List result_fetch(PqResult* rs, int n) {
  return rs->fetch(n);
}

// [[Rcpp::export]]
void result_bind_params(PqResult* rs, List params) {
  return rs->bind(params);
}

// [[Rcpp::export]]
bool result_is_complete(PqResult* rs) {
  try {
    return rs->is_complete();
  } catch (...) {
    return false;
  }
}

// [[Rcpp::export]]
void result_release(XPtr<PqResult> rs) {
  rs.release();
}

// [[Rcpp::export]]
bool result_active(XPtr<PqResult> rs_) {
  PqResult* rs = rs_.get();
  return rs != NULL && rs->active();
}

// [[Rcpp::export]]
int result_rows_fetched(PqResult* rs) {
  return rs->n_rows_fetched();
}

// [[Rcpp::export]]
int result_rows_affected(PqResult* rs) {
  return rs->n_rows_affected();
}

// [[Rcpp::export]]
List result_column_info(PqResult* rs) {
  return rs->get_column_info();
}

namespace Rcpp {

template<>
PqResult* as(SEXP x) {
  PqResult* result = (PqResult*)(R_ExternalPtrAddr(x));
  if (!result)
    stop("Invalid result set");
  return result;
}

}
