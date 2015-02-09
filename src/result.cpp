#include <Rcpp.h>
#include "rpq_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqResult> rpostgres_send_query(XPtr<PqConnectionPtr> con, std::string sql) {
  PqResult* res = new PqResult(*con, sql);
  return XPtr<PqResult>(res, true);
}

// [[Rcpp::export]]
List postgres_fetch(XPtr<PqResult> rs, int n) {
  if (n >= 0) {
    return rs->fetch(n);
  } else {
    return rs->fetch_all();
  }
}

// [[Rcpp::export]]
int rows_affected(XPtr<PqResult> rs) {
  return rs->rowsAffected();
}

// [[Rcpp::export]]
bool is_complete(XPtr<PqResult> rs) {
  return rs->is_complete();
}

// [[Rcpp::export]]
void clear_result(XPtr<PqResult> rs) {
  rs.release();
}

// [[Rcpp::export]]
bool postgres_result_valid(XPtr<PqResult> rs) {
  return rs->active();
}

// [[Rcpp::export]]
int postgres_row_count(XPtr<PqResult> rs) {
  return rs->nrows();
}
