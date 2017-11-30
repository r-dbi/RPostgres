#include "pch.h"
#include "RPostgres_types.h"


// [[Rcpp::export]]
XPtr<DbResult> result_create(XPtr<DbConnectionPtr> con, std::string sql) {
  DbResult* res = new DbResult(*con, sql);
  return XPtr<DbResult>(res, true);
}

// [[Rcpp::export]]
void result_release(XPtr<DbResult> res) {
  res.release();
}

// [[Rcpp::export]]
List result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

// [[Rcpp::export]]
void result_bind(DbResult* res, List params) {
  return res->bind(params);
}

// [[Rcpp::export]]
bool result_is_complete(DbResult* rs) {
  try {
    return rs->is_complete();
  } catch (...) {
    return false;
  }
}

// [[Rcpp::export]]
bool result_active(XPtr<DbResult> rs_) {
  DbResult* rs = rs_.get();
  return rs != NULL && rs->active();
}

// [[Rcpp::export]]
int result_rows_fetched(DbResult* rs) {
  return rs->n_rows_fetched();
}

// [[Rcpp::export]]
int result_rows_affected(DbResult* rs) {
  return rs->n_rows_affected();
}

// [[Rcpp::export]]
List result_column_info(DbResult* rs) {
  return rs->get_column_info();
}

namespace Rcpp {

template<>
DbResult* as(SEXP x) {
  DbResult* result = (DbResult*)(R_ExternalPtrAddr(x));
  if (!result)
    stop("Invalid result set");
  return result;
}

}
