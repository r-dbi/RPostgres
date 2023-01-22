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
    warning("Already disconnected");
    return;
  }

  DbConnectionPtr* con = con_.get();
  if (con->get()->has_query()) {
    warning("%s\n%s",
            "There is a result object still in use.",
            "The connection will be automatically released when it is closed"
           );
  }

  con->get()->disconnect();
  con_.release();
}

[[cpp11::register]]
List connection_info(DbConnection* con) {
  return con->info();
}

// Quoting

[[cpp11::register]]
CharacterVector connection_quote_string(DbConnection* con, CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    String x = xs[i];
    output[i] = con->quote_string(x);
  }

  return output;
}

[[cpp11::register]]
CharacterVector connection_quote_identifier(DbConnection* con, CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    String x = xs[i];
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
void connection_copy_data(DbConnection* con, std::string sql, List df) {
  return con->copy_data(sql, df);
}

[[cpp11::register]]
List connection_wait_for_notify(DbConnection* con, int timeout_secs) {
  return con->wait_for_notify(timeout_secs);
}

// Temporary Schema
[[cpp11::register]]
CharacterVector connection_get_temp_schema(DbConnection* con) {
  return con->get_temp_schema();
}
[[cpp11::register]]
void connection_set_temp_schema(DbConnection* con, CharacterVector temp_schema) {
  con->set_temp_schema(temp_schema);
}