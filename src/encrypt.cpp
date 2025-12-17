#include "pch.h"


[[cpp4r::register]]
std::string encrypt_password(cpp4r::r_string password, cpp4r::r_string user) {
  const auto pass = static_cast<std::string>(password);
  const auto u = static_cast<std::string>(user);

  const char* encrypted = PQencryptPassword(pass.c_str(), u.c_str());
  
  return encrypted;
}
