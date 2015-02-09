#ifndef __RSQLITE_PQ_UTILS__
#define __RSQLITE_PQ_UTILS__

#include <Rcpp.h>
#include <libpq-fe.h>

Rcpp::List inline df_resize(Rcpp::List df, int n) {
  int p = df.size();

  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_lengthgets(df[j], n);
  }

  return out;
}

Rcpp::List inline df_create(std::vector<SEXPTYPE> types, int n) {
  int p = types.size();

  Rcpp::List out(p);
  for (int j = 0; j < p; ++j) {
    out[j] = Rf_allocVector(types[j], n);
  }
  return out;
}

#endif
