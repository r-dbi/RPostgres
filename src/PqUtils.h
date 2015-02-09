#ifndef __RSQLITE_PQ_UTILS__
#define __RSQLITE_PQ_UTILS__

#include <Rcpp.h>
#include <libpq-fe.h>

inline Rcpp::IntegerVector int_fill_col(PGresult* res, int j, int n) {
  Rcpp::IntegerVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_INTEGER;
    } else {
      col[i] = atoi(PQgetvalue(res, i, j));
    }
  }

  return col;
}

inline Rcpp::NumericVector real_fill_col(PGresult* res, int j, int n) {
  Rcpp::NumericVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_REAL;
    } else {
      col[i] = atof(PQgetvalue(res, i, j));
    }
  }

  return col;
}

inline Rcpp::CharacterVector str_fill_col(PGresult* res, int j, int n) {
  Rcpp::CharacterVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_STRING;
    } else {
      char* val = PQgetvalue(res, i, j);
      col[i] = Rf_mkCharCE(val, CE_UTF8);
    }
  }

  return col;
}

inline Rcpp::LogicalVector lgl_fill_col(PGresult* res, int j, int n) {
  Rcpp::LogicalVector col(n);
  for (int i = 0; i < n; ++i) {
    if (PQgetisnull(res, i, j)) {
      col[i] = NA_LOGICAL;
    } else {
      col[i] = (strcmp(PQgetvalue(res, i, j), "t") == 0);
    }
  }

  return col;
}


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
