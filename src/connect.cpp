#include <Rcpp.h>
#include "rpq_types.h"
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqConnection> connect(std::vector<std::string> keys, std::vector<std::string> values) {
  PqConnection* conn = new PqConnection(keys, values);
  return XPtr<PqConnection>(conn, true);
}

// [[Rcpp::export]]
void exec(XPtr<PqConnection> con, std::string query) {
  con->exec(query);
}

// [[Rcpp::export]]
List exception_info(XPtr<PqConnection> con) {
  return con->exception_info();
}

// [[Rcpp::export]]
List con_info(XPtr<PqConnection> con) {
  return con->con_info();
}

// [[Rcpp::export]]
int rows_affected(XPtr<PqConnection> con) {
  return con->rows_affected();
}

// [[Rcpp::export]]
bool is_complete(XPtr<PqConnection> con) {
  return con->is_complete();
}


// [[Rcpp::export]]
List fetch(XPtr<PqConnection> con) {
  return con->fetch();
}


// [[Rcpp::export]]
void disconnect(XPtr<PqConnection> con) {
  con.release();
}

// [[Rcpp::export]]
void clear_result(XPtr<PqConnection> con) {
  return con->clear_result();
}

// [[Rcpp::export]]
CharacterVector escape_string(XPtr<PqConnection> con, CharacterVector xs) {
  int n = xs.size();
  CharacterVector escaped(n);

  for (int i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = con->escape_string(x);
  }

  return escaped;
}

// [[Rcpp::export]]
CharacterVector escape_identifier(XPtr<PqConnection> con, CharacterVector xs) {
  int n = xs.size();
  CharacterVector escaped(n);

  for (int i = 0; i < n; ++i) {
    std::string x(xs[i]);
    escaped[i] = con->escape_identifier(x);
  }

  return escaped;
}
