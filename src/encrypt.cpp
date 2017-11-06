#include "pch.h"


// [[Rcpp::export]]
String encrypt_password(String password, String user) {
  char* encrypted = PQencryptPassword(password.get_cstring(), user.get_cstring());

  String copy(encrypted);
  PQfreemem(encrypted);

  return copy;
}
