#ifndef __RPOSTGRES_PQ_UTILS__
#define __RPOSTGRES_PQ_UTILS__

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

Rcpp::List dfResize(Rcpp::List df, int n);
Rcpp::List dfCreate(const std::vector<PGTypes>& types, const std::vector<std::string>& names, int n);

#endif
