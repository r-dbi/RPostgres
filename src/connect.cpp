#include <Rcpp.h>
#include <rpq.h>
using namespace Rcpp;

// [[Rcpp::export]]
XPtr<PqConnection> connect(std::vector<std::string> keys, std::vector<std::string> values) {
  PqConnection* conn = new PqConnection(keys, values);
  return XPtr<PqConnection>(conn, true);
}

