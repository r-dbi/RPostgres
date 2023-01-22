#include "pch.h"


[[cpp11::register]]
cpp11::r_string encrypt_password(cpp11::r_string password, cpp11::r_string user) {
  const auto pass = static_cast<std::string>(password);
  const auto u = static_cast<std::string>(user);

  const char* encrypted = PQencryptPassword(pass.c_str(), u.c_str());
  
  return encrypted;
}
