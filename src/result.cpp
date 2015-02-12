#include <Rcpp.h>
#include "RPostgres_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqResult> result_create(XPtr<PqConnectionPtr> con, std::string sql) {
  PqResult* res = new PqResult(*con, sql);
  return XPtr<PqResult>(res, true);
}

// [[Rcpp::export]]
List result_fetch(XPtr<PqResult> rs, int n) {
  return rs->fetch(n);
}

// [[Rcpp::export]]
void result_bind_params(XPtr<PqResult> rs, ListOf<CharacterVector> params) {
  return rs->bind(params);
}

// [[Rcpp::export]]
bool result_is_complete(XPtr<PqResult> rs) {
  return rs->isComplete();
}

// [[Rcpp::export]]
void result_release(XPtr<PqResult> rs) {
  rs.release();
}

// [[Rcpp::export]]
bool result_active(XPtr<PqResult> rs) {
  return rs->active();
}

// [[Rcpp::export]]
int result_rows_fetched(XPtr<PqResult> rs) {
  return rs->rowsFetched();
}

// [[Rcpp::export]]
int result_rows_affected(XPtr<PqResult> rs) {
  return rs->rowsAffected();
}

// [[Rcpp::export]]
List result_column_info(XPtr<PqResult> rs) {
  return rs->columnInfo();
}
