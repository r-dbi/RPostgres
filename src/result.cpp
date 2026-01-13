#include "pch.h"
#include "RPostgres_types.h"
#include "PqResult.h"


[[cpp4r::register]]
cpp4r::external_pointer<DbResult> result_create(cpp4r::external_pointer<DbConnectionPtr> con, std::string sql, bool immediate) {
  (*con)->check_connection();
  DbResult* res = PqResult::create_and_send_query(*con, sql, immediate);
  return cpp4r::external_pointer<DbResult>(res, true);
}

[[cpp4r::register]]
void result_release(cpp4r::external_pointer<DbResult> res) {
  res.reset();
}

[[cpp4r::register]]
bool result_valid(cpp4r::external_pointer<DbResult> res_) {
  DbResult* res = res_.get();
  return res != NULL && res->is_active();
}

[[cpp4r::register]]
cpp4r::list result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

[[cpp4r::register]]
void result_bind(DbResult* res, cpp4r::list params) {
  res->bind(params);
}

[[cpp4r::register]]
bool result_has_completed(DbResult* res) {
  return res->complete();
}

[[cpp4r::register]]
int result_rows_fetched(DbResult* res) {
  return res->n_rows_fetched();
}

[[cpp4r::register]]
int result_rows_affected(DbResult* res) {
  return res->n_rows_affected();
}

[[cpp4r::register]]
cpp4r::list result_column_info(DbResult* res) {
  return res->get_column_info();
}
