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

  virtual int fetch_int() const = 0;
  virtual int64_t fetch_int64() const = 0;
  virtual double fetch_real() const = 0;
  virtual SEXP fetch_string() const = 0;
  virtual SEXP fetch_blob() const = 0;

protected:
  int get_j() const;
};

#endif //DB_COLUMNDATASOURCE_H
