#include "pch.h"
#include "RPostgres_types.h"


// [[Rcpp::export]]
int client_version() {
  return PQlibVersion();
}

// [[Rcpp::export]]
XPtr<DbConnectionPtr> connection_create(
  std::vector<std::string> keys,
  std::vector<std::string> values,
  bool check_interrupts
) {
  LOG_VERBOSE;

  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(keys, values, check_interrupts)
  );

  return XPtr<DbConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
bool connection_valid(XPtr<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  return con;
}

// [[Rcpp::export]]
void connection_release(XPtr<DbConnectionPtr> con_) {
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

// [[Rcpp::export]]
List connection_info(DbConnection* con) {
  return con->info();
}

// Quoting

// [[Rcpp::export]]
CharacterVector connection_quote_string(DbConnection* con, CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector output(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    String x = xs[i];
    output[i] = con->quote_string(x);
  }

  return output;
}

// [[Rcpp::export]]
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

// [[Rcpp::export]]
bool connection_is_transacting(DbConnection* con) {
  return con->is_transacting();
}

// [[Rcpp::export]]
void connection_set_transacting(DbConnection* con, bool transacting) {
  con->set_transacting(transacting);
}

// Specific functions

// [[Rcpp::export]]
void connection_copy_data(DbConnection* con, std::string sql, List df) {
  return con->copy_data(sql, df);
}

// [[Rcpp::export]]
List connection_wait_for_notify(DbConnection* con, int timeout_secs) {
  return con->wait_for_notify(timeout_secs);
}

// Temporary Schema
// [[Rcpp::export]]
CharacterVector connection_get_temp_schema(DbConnection* con) {
  return con->get_temp_schema();
}
// [[Rcpp::export]]
void connection_set_temp_schema(DbConnection* con, CharacterVector temp_schema) {
  con->set_temp_schema(temp_schema);
}

// as() override

namespace Rcpp {

template<>
DbConnection* as(SEXP x) {
  DbConnectionPtr* connection = (DbConnectionPtr*)(R_ExternalPtrAddr(x));
  if (!connection)
    stop("Invalid connection");
  return connection->get();
}

}
