#include <Rcpp.h>
#include "RPostgres_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqConnectionPtr> connect(std::vector<std::string> keys, std::vector<std::string> values) {
  PqConnectionPtr* pConn = new PqConnectionPtr(
    new PqConnection(keys, values)
  );
  return XPtr<PqConnectionPtr>(pConn, true);
}

// [[Rcpp::export]]
List con_info(XPtr<PqConnectionPtr> con) {
  return (*con)->info();
}

// [[Rcpp::export]]
void postgres_disconnect(XPtr<PqConnectionPtr> con) {
  if ((*con)->has_query()) {
    warning("%s\n%s",
      "There is a result object still in use.",
      "The connection will be automatically released when it is closed"
    );
  }
  con.release();
}

// [[Rcpp::export]]
CharacterVector escape_string(XPtr<PqConnectionPtr> con, CharacterVector xs) {
  int n = xs.size();
  CharacterVector escaped(n);

  for (int i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = (*con)->escape_string(x);
  }

  return escaped;
}

// [[Rcpp::export]]
CharacterVector escape_identifier(XPtr<PqConnectionPtr> con, CharacterVector xs) {
  int n = xs.size();
  CharacterVector escaped(n);

  for (int i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = (*con)->escape_identifier(x);
  }

  return escaped;
}

// [[Rcpp::export]]
void postgresql_copy_data(XPtr<PqConnectionPtr> con, std::string sql, List df) {
  return (*con)->copy_data(sql, df);
}
