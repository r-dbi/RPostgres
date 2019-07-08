#include "pch.h"
#include "DbResult.h"
#include "DbConnection.h"
#include "PqResultImpl.h"



// Construction ////////////////////////////////////////////////////////////////

DbResult::DbResult(const DbConnectionPtr& pConn, const std::string& sql, const bool check_interrupts) :
  pConn_(pConn)
{
  pConn->check_connection();
  pConn->set_current_result(this);

  try {
    impl.reset(new PqResultImpl(this, pConn->conn(), sql, check_interrupts));
  }
  catch (...) {
    pConn->set_current_result(NULL);
    throw;
  }
}

DbResult::~DbResult() {
  try {
    if (is_active()) {
      pConn_->set_current_result(NULL);
    }
  } catch (...) {}
}

DbResult* DbResult::create_and_send_query(const DbConnectionPtr& con, const std::string& sql, bool is_statement, const bool check_interrupts) {
  (void)is_statement;
  return new DbResult(con, sql, check_interrupts);
}


// Publics /////////////////////////////////////////////////////////////////////

bool DbResult::complete() const {
  return (impl == NULL) || impl->complete();
}

bool DbResult::is_active() const {
  return pConn_->is_current_result(this);
}

int DbResult::n_rows_fetched() {
  return impl->n_rows_fetched();
}

int DbResult::n_rows_affected() {
  return impl->n_rows_affected();
}

void DbResult::bind(const List& params) {
  impl->bind(params);
}

List DbResult::fetch(const int n_max) {
  if (!is_active())
    stop("Inactive result set");

  return impl->fetch(n_max);
}

List DbResult::get_column_info() {
  return impl->get_column_info();
}

void DbResult::finish_query() {
  pConn_->finish_query();
}

// Privates ///////////////////////////////////////////////////////////////////
