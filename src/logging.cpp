#include "pch.h"
#include <plogr.h>


// [[Rcpp::export]]
void init_logging(const std::string& log_level) {
  plog::init_r(log_level);
}
