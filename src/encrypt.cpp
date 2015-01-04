#include <Rcpp.h>
#include <libpq-fe.h>
using namespace Rcpp;

// [[Rcpp::export]]
String encrypt_password(String password, String user) {
  char* encrypted = PQencryptPassword(password.get_cstring(), user.get_cstring());

  String copy(encrypted);
  PQfreemem(encrypted);

  return copy;
}
