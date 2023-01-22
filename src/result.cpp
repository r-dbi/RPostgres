#include "pch.h"
#include "RPostgres_types.h"
#include "PqResult.h"


[[cpp11::register]]
cpp11::external_pointer<DbResult> result_create(cpp11::external_pointer<DbConnectionPtr> con, std::string sql, bool immediate) {
  (*con)->check_connection();
  DbResult* res = PqResult::create_and_send_query(*con, sql, immediate);
  return cpp11::external_pointer<DbResult>(res, true);
}

[[cpp11::register]]
void result_release(cpp11::external_pointer<DbResult> res) {
  res.reset();
}

[[cpp11::register]]
bool result_valid(cpp11::external_pointer<DbResult> res_) {
  DbResult* res = res_.get();
  return res != NULL && res->is_active();
}

[[cpp11::register]]
List result_fetch(DbResult* res, const int n) {
  return res->fetch(n);
}

[[cpp11::register]]
void result_bind(DbResult* res, List params) {
  res->bind(params);
}

[[cpp11::register]]
bool result_has_completed(DbResult* res) {
  return res->complete();
}

[[cpp11::register]]
int result_rows_fetched(DbResult* res) {
  return res->n_rows_fetched();
}

[[cpp11::register]]
int result_rows_affected(DbResult* res) {
  return res->n_rows_affected();
}

[[cpp11::register]]
List result_column_info(DbResult* res) {
  return res->get_column_info();
}
