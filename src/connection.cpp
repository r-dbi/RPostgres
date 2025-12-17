#include "pch.h"
#include "RPostgres_types.h"


[[cpp4r::register]]
int client_version() {
  return PQlibVersion();
}

[[cpp4r::register]]
cpp4r::external_pointer<DbConnectionPtr> connection_create(
  std::vector<std::string> keys,
  std::vector<std::string> values,
  bool check_interrupts
) {
  LOG_VERBOSE;

  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(keys, values, check_interrupts)
  );

  return cpp4r::external_pointer<DbConnectionPtr>(pConn, true);
}

[[cpp4r::register]]
bool connection_valid(cpp4r::external_pointer<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  return con;
}

[[cpp4r::register]]
void connection_release(cpp4r::external_pointer<DbConnectionPtr> con_) {
  if (!connection_valid(con_)) {
    cpp4r::warning(std::string("Already disconnected"));
    return;
  }

  DbConnectionPtr* con = con_.get();
  if (con->get()->has_query()) {
    cpp4r::warning(std::string("There is a result object still in use.\n"
      "The connection will be automatically released when it is closed"));
  }

  con->get()->disconnect();
  con_.reset();
}

[[cpp4r::register]]
cpp4r::list connection_info(DbConnection* con) {
  return con->info();
}

// Quoting

[[cpp4r::register]]
cpp4r::strings connection_quote_string(DbConnection* con, cpp4r::strings xs) {
  const auto n = xs.size();
  cpp4r::writable::strings output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    auto x = xs[i];
    output[i] = con->quote_string(x);
  }

  return output;
}

[[cpp4r::register]]
cpp4r::strings connection_quote_identifier(DbConnection* con, cpp4r::strings xs) {
  const auto n = xs.size();
  cpp4r::writable::strings output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    auto x = xs[i];
    output[i] = con->quote_identifier(x);
  }

  return output;
}

// Transactions

[[cpp4r::register]]
bool connection_is_transacting(DbConnection* con) {
  return con->is_transacting();
}

[[cpp4r::register]]
void connection_set_transacting(DbConnection* con, bool transacting) {
  con->set_transacting(transacting);
}

// Specific functions
[[cpp4r::register]]
Oid connection_import_lo_from_file(DbConnection* con, std::string filename, Oid oid) {
  return con->import_lo_from_file(filename, oid);
}

[[cpp4r::register]]
void connection_export_lo_to_file(DbConnection* con, Oid oid, std::string filename) {
  con->export_lo_to_file(oid, filename);
}

[[cpp4r::register]]
void connection_copy_data(DbConnection* con, std::string sql, cpp4r::list df) {
  return con->copy_data(sql, df);
}

[[cpp4r::register]]
cpp4r::list connection_wait_for_notify(DbConnection* con, int timeout_secs) {
  return con->wait_for_notify(timeout_secs);
}

// Temporary Schema
[[cpp4r::register]]
cpp4r::strings connection_get_temp_schema(DbConnection* con) {
  return con->get_temp_schema();
}

[[cpp4r::register]]
void connection_set_temp_schema(DbConnection* con, cpp4r::strings temp_schema) {
  con->set_temp_schema(temp_schema);
}
