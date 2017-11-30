#ifndef __RPOSTGRES_PQ_UTILS__
#define __RPOSTGRES_PQ_UTILS__

// Generic data frame utils ----------------------------------------------------

enum DATA_TYPE {
  DT_UNKNOWN,
  DT_BOOL,
  DT_INT,
  DT_INT64,
  DT_REAL,
  DT_STRING,
  DT_BLOB,
  DT_DATE,
  DT_DATETIME,
  DT_DATETIMETZ,
  DT_TIME
};

List df_resize(Rcpp::List df, int n);
List df_create(const std::vector<DATA_TYPE>& types, const std::vector<std::string>& names, int n);

#endif
