#ifndef __RPOSTGRES_PQ_UTILS__
#define __RPOSTGRES_PQ_UTILS__

// Generic data frame utils ----------------------------------------------------

enum PGTypes {
  PGInt,
  PGReal,
  PGString,
  PGLogical,
  PGVector,
  PGInt64,
  PGDate,
  PGDatetime,
  PGDatetimeTZ,
  PGTime
};

List df_resize(Rcpp::List df, int n);
List df_create(const std::vector<PGTypes>& types, const std::vector<std::string>& names, int n);

#endif
