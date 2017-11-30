#ifndef DB_COLUMNDATASOURCE_H
#define DB_COLUMNDATASOURCE_H

#include "DbColumnDataType.h"

class DbColumnDataSource {
  const int j;

protected:
  DbColumnDataSource(const int j);

public:
  virtual ~DbColumnDataSource();

public:
  virtual DATA_TYPE get_data_type() const = 0;
  virtual DATA_TYPE get_decl_data_type() const = 0;

  virtual bool is_null() const = 0;

  virtual void fetch_int(SEXP x, int i) const = 0;
  virtual void fetch_int64(SEXP x, int i) const = 0;
  virtual void fetch_real(SEXP x, int i) const = 0;
  virtual void fetch_string(SEXP x, int i) const = 0;
  virtual void fetch_blob(SEXP x, int i) const = 0;

protected:
  int get_j() const;
};

#endif //DB_COLUMNDATASOURCE_H
