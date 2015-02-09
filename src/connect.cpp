#include <Rcpp.h>
#include "rpq_types.h"
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
void disconnect(XPtr<PqConnectionPtr> con) {
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
