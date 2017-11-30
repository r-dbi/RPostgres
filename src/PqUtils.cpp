#include "pch.h"
#include "PqUtils.h"
#include "integer64.h"


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

List df_create(const std::vector<DATA_TYPE>& types, const std::vector<std::string>& names, int n) {
  R_xlen_t p = types.size();

  List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -n);

  int j = 0;
  for (std::vector<DATA_TYPE>::const_iterator it = types.begin(); it != types.end(); ++it, j++) {
    switch (*it) {
    case DT_INT:
      out[j] = Rf_allocVector(INTSXP, n);
      break;

    case DT_REAL:
      out[j] = Rf_allocVector(REALSXP, n);
      break;

    case DT_BOOL:
      out[j] = Rf_allocVector(LGLSXP, n);
      break;

    case DT_STRING:
      out[j] = Rf_allocVector(STRSXP, n);
      break;

    case DT_BLOB:
      out[j] = Rf_allocVector(VECSXP, n);
      break;

    case DT_DATE:
    case DT_DATETIME:
    case DT_DATETIMETZ:
    case DT_TIME:
      out[j] = Rf_allocVector(REALSXP, n);
      break;

    case DT_INT64:
      out[j] = Rf_allocVector(INT64SXP, n);
      break;

    default:
      stop("Unknown datatype %d", *it);
    }
  }
  return out;
}
