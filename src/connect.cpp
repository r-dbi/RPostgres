#include <Rcpp.h>
#include <rpq.h>
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
List exception_details(XPtr<PqConnection> con) {
  return con->exception_details();
}

// [[Rcpp::export]]
int rows_affected(XPtr<PqConnection> con) {
  return con->rows_affected();
}

// [[Rcpp::export]]
void disconnect(XPtr<PqConnection> con) {
  return con->disconnect();
}
