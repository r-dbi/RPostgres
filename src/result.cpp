#include <Rcpp.h>
#include "rpq_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqResult> exec(XPtr<PqConnectionPtr> con, std::string sql) {
  PqResult* res = new PqResult(*con, sql);
  return XPtr<PqResult>(res, true);
}

// [[Rcpp::export]]
List fetch(XPtr<PqResult> rs) {
  return rs->fetch();
}

// [[Rcpp::export]]
int rows_affected(XPtr<PqResult> rs) {
  return rs->rows_affected();
}

// [[Rcpp::export]]
bool is_complete(XPtr<PqResult> rs) {
  return rs->is_complete();
}

// [[Rcpp::export]]
void clear_result(XPtr<PqResult> con) {
  con.release();
}
