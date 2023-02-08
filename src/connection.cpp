#include "pch.h"
#include "RPostgres_types.h"


[[cpp11::register]]
int client_version() {
  return PQlibVersion();
}

[[cpp11::register]]
cpp11::external_pointer<DbConnectionPtr> connection_create(
  std::vector<std::string> keys,
  std::vector<std::string> values,
  bool check_interrupts
) {
  LOG_VERBOSE;

  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(keys, values, check_interrupts)
  );

  return cpp11::external_pointer<DbConnectionPtr>(pConn, true);
}

[[cpp11::register]]
bool connection_valid(cpp11::external_pointer<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  return con;
}

[[cpp11::register]]
void connection_release(cpp11::external_pointer<DbConnectionPtr> con_) {
  if (!connection_valid(con_)) {
    cpp11::warning(std::string("Already disconnected"));
    return;
  }

  DbConnectionPtr* con = con_.get();
  if (con->get()->has_query()) {
    cpp11::warning(std::string("There is a result object still in use.\n"
      "The connection will be automatically released when it is closed"));
    return;
  }

  con->get()->disconnect();
  con_.reset();
}

[[cpp11::register]]
cpp11::list connection_info(DbConnection* con) {
  return con->info();
}

// Quoting

[[cpp11::register]]
cpp11::strings connection_quote_string(DbConnection* con, cpp11::strings xs) {
  const auto n = xs.size();
  cpp11::writable::strings output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    auto x = xs[i];
    output[i] = con->quote_string(x);
  }

  return output;
}

[[cpp11::register]]
cpp11::strings connection_quote_identifier(DbConnection* con, cpp11::strings xs) {
  const auto n = xs.size();
  cpp11::writable::strings output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    auto x = xs[i];
    output[i] = con->quote_identifier(x);
  }

  return output;
}

// Transactions

[[cpp11::register]]
bool connection_is_transacting(DbConnection* con) {
  return con->is_transacting();
}

[[cpp11::register]]
void connection_set_transacting(DbConnection* con, bool transacting) {
  con->set_transacting(transacting);
}

// Specific functions

[[cpp11::register]]
void connection_copy_data(DbConnection* con, std::string sql, cpp11::list df) {
  return con->copy_data(sql, df);
}

[[cpp11::register]]
cpp11::list connection_wait_for_notify(DbConnection* con, int timeout_secs) {
  return con->wait_for_notify(timeout_secs);
}

// Temporary Schema
[[cpp11::register]]
cpp11::strings connection_get_temp_schema(DbConnection* con) {
  return con->get_temp_schema();
}

[[cpp11::register]]
void connection_set_temp_schema(DbConnection* con, cpp11::strings temp_schema) {
  con->set_temp_schema(temp_schema);
}
