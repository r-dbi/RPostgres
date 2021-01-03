#ifndef RPOSTGRES_PQCOLUMNDATASOURCE_H
#define RPOSTGRES_PQCOLUMNDATASOURCE_H

#include "DbColumnDataSource.h"

class PqResultSource;
class PqColumnDataSourceFactory;

class PqColumnDataSource : public DbColumnDataSource {
  PqResultSource* result_source;
  const DATA_TYPE dt;
  const int utcoffset;

public:
  PqColumnDataSource(PqResultSource* result_source_, const DATA_TYPE dt_, const int j, const int utcoffset);
  virtual ~PqColumnDataSource();

public:
  virtual DATA_TYPE get_data_type() const;
  virtual DATA_TYPE get_decl_data_type() const;

  virtual bool is_null() const;

  virtual int fetch_bool() const;
  virtual int fetch_int() const;
  virtual int64_t fetch_int64() const;
  virtual double fetch_real() const;
  virtual SEXP fetch_string() const;
  virtual SEXP fetch_blob() const;
  virtual double fetch_date() const;
  virtual double fetch_datetime_local() const;
  virtual double fetch_datetime() const;
  virtual double fetch_time() const;

private:
  static double convert_datetime(const char* val, int utcoffset);
  PGresult* get_result() const;
  const char* get_result_value() const;
};

#endif //RPOSTGRES_PQCOLUMNDATASOURCE_H
