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

List dfResize(Rcpp::List df, int n);
List dfCreate(const std::vector<PGTypes>& types, const std::vector<std::string>& names, int n);

#endif
