#include "pch.h"
#include "RPostgres_types.h"


// [[Rcpp::export]]
XPtr<PqConnectionPtr> connection_create(std::vector<std::string> keys,
                                        std::vector<std::string> values) {
  PqConnectionPtr* pConn = new PqConnectionPtr(
    new PqConnection(keys, values)
  );
  return XPtr<PqConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
void connection_release(XPtr<PqConnectionPtr> con) {
  if (con.get() != NULL) {
    if ((*con)->has_query()) {
      warning("%s\n%s",
              "There is a result object still in use.",
              "The connection will be automatically released when it is closed"
             );
    }
    con.release();
  } else {
    warning("connections is invalid");
  }
}

// [[Rcpp::export]]
List connection_info(XPtr<PqConnectionPtr> con) {
  return (*con)->info();
}

// [[Rcpp::export]]
CharacterVector connection_escape_string(XPtr<PqConnectionPtr> con,
                                         CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector escaped(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    if (CharacterVector::is_na(xs[i])) {
      escaped[i] = "NULL";
    }
    else {
      escaped[i] = (*con)->escape_string(std::string(xs[i]));
    }
  }

  return escaped;
}

// [[Rcpp::export]]
CharacterVector connection_escape_identifier(XPtr<PqConnectionPtr> con,
    CharacterVector xs) {
  R_xlen_t n = xs.size();
  CharacterVector escaped(n);

  for (R_xlen_t i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = (*con)->escape_identifier(x);
  }

  return escaped;
}

// [[Rcpp::export]]
void connection_copy_data(XPtr<PqConnectionPtr> con, std::string sql, List df) {
  return (*con)->copy_data(sql, df);
}
