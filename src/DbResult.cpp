#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "PqResultImpl.h"


DbResult::DbResult(const DbConnectionPtr& pConn, const std::string& sql) :
  pConn_(pConn)
{
  pConn->check_connection();
  pConn->set_current_result(this);

  try {
    impl.reset(new PqResultImpl(this, pConn->conn(), sql));
  }
  catch (...) {
    pConn->set_current_result(NULL);
    throw;
  }
}

DbResult::~DbResult() {
  try {
    if (active()) {
      pConn_->set_current_result(NULL);
    }
  } catch (...) {}
}

DbResult* DbResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql, bool is_statement) {
  (void)is_statement;
  return new DbResult(con, sql);
}

void DbResult::bind(const List& params) {
  return impl->bind(params);
}

bool DbResult::active() const {
  return pConn_->is_current_result(this);
}

List DbResult::fetch(int n_max) {
  if (!active())
    stop("Inactive result set");

  return impl->fetch(n_max);
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

int DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

bool DbResult::complete() const {
  return (impl == NULL) || impl->complete();
}

List DbResult::get_column_info() {
  return impl->get_column_info();
}

void DbResult::finish_query() {
  pConn_->finish_query();
}
