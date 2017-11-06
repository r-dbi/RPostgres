#include "pch.h"
#include "PqUtils.h"


List df_resize(Rcpp::List df, int n) {
  R_xlen_t p = df.size();

  List out(p);
  for (R_xlen_t j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }

  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);

  return out;
}

List df_create(const std::vector<PGTypes>& types, const std::vector<std::string>& names, int n) {
  R_xlen_t p = types.size();

  List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);

  int j = 0;
  for (std::vector<PGTypes>::const_iterator it = types.begin(); it != types.end(); ++it, j++) {
    switch (*it) {
    case PGDate:
    case PGDatetime:
    case PGDatetimeTZ:
    case PGTime:
      out[j] = Rf_allocVector(REALSXP, n);
      break;
    default:
      out[j] = Rf_allocVector(static_cast<SEXPTYPE>(*it), n);
    }
  }
  return out;
}
