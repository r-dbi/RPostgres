#ifndef __RSQLITE_PQ_UTILS__
#define __RSQLITE_PQ_UTILS__

#include <Rcpp.h>
#include <libpq-fe.h>

// Defined in encode.cpp -------------------------------------------------------

void escapeInBuffer(const char* string, std::string& buffer);
void encodeInBuffer(Rcpp::RObject x, int i, std::string& buffer);
void encodeRowInBuffer(Rcpp::List x, int i, std::string& buffer,
  std::string fieldDelim = "\t",
  std::string lineDelim = "\n");
std::string encode_data_frame(Rcpp::List x);

// Generic data frame utils ----------------------------------------------------

enum PGTypes {
  PGInt = INTSXP,
  PGReal = REALSXP,
  PGString = STRSXP,
  PGLogical = LGLSXP,
  PGVector = VECSXP,
  PGDate,
  PGDatetime,
  PGDatetimeTZ,
  PGTime
};

Rcpp::List inline dfResize(Rcpp::List df, int n) {
  R_xlen_t p = df.size();

  Rcpp::List out(p);
  for (R_xlen_t j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }

  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  return out;
}

Rcpp::List inline dfCreate(const std::vector<PGTypes>& types, const std::vector<std::string>& names, int n) {
  R_xlen_t p = types.size();

  Rcpp::List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

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

#endif
