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

Rcpp::List inline df_resize(Rcpp::List df, int n) {
  int p = df.size();

  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }

  out.attr("names") = df.attr("names");
  out.attr("class") = df.attr("class");
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  return out;
}

Rcpp::List inline df_create(std::vector<SEXPTYPE> types, std::vector<std::string> names, int n) {
  int p = types.size();

  Rcpp::List out(p);
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);

  for (int j = 0; j < p; ++j) {
    out[j] = Rf_allocVector(types[j], n);
  }
  return out;
}

#endif
