#include "pch.h"
#include "RPostgres_types.h"


// [[Rcpp::export]]
XPtr<DbConnectionPtr> connection_create(std::vector<std::string> keys,
                                        std::vector<std::string> values) {
  DbConnectionPtr* pConn = new DbConnectionPtr(
    new DbConnection(keys, values)
  );
  return XPtr<DbConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
bool connection_is_valid(XPtr<DbConnectionPtr> con) {
  return (con.get() != NULL);
}

// [[Rcpp::export]]
void connection_release(XPtr<DbConnectionPtr> con_) {
  DbConnectionPtr* con = con_.get();
  if (con != NULL) {
    if (con->get()->has_query()) {
      warning("%s\n%s",
              "There is a result object still in use.",
              "The connection will be automatically released when it is closed"
             );
    }
    con_.release();
  } else {
    warning("connections is invalid");
  }
}

// [[Rcpp::export]]
List connection_info(DbConnection* con) {
  return con->info();
}

// [[Rcpp::export]]
CharacterVector connection_escape_string(DbConnection* con, CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector escaped(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    if (CharacterVector::is_na(xs[i])) {
      escaped[i] = "NULL";
    }
    else {
      escaped[i] = con->escape_string(std::string(xs[i]));
    }
  }

  return escaped;
}

// [[Rcpp::export]]
CharacterVector connection_escape_identifier(DbConnection* con, CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector escaped(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = con->escape_identifier(x);
  }

  return escaped;
}

// [[Rcpp::export]]
void connection_copy_data(DbConnection* con, std::string sql, List df) {
  return con->copy_data(sql, df);
}

// [[Rcpp::export]]
bool connection_is_transacting(DbConnection* con) {
  return con->is_transacting();
}

// [[Rcpp::export]]
void connection_set_transacting(DbConnection* con, bool transacting) {
  con->set_transacting(transacting);
}

namespace Rcpp {

template<>
DbConnection* as(SEXP x) {
  DbConnectionPtr* connection = (DbConnectionPtr*)(R_ExternalPtrAddr(x));
  if (!connection)
    stop("Invalid connection");
  return connection->get();
}

}
