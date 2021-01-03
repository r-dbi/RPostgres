#ifndef RPOSTGRES_PQCOLUMNDATASOURCEFACTORY_H
#define RPOSTGRES_PQCOLUMNDATASOURCEFACTORY_H

#include "DbColumnDataSourceFactory.h"
#include "DbColumnDataType.h"

class PqResultSource;

class PqColumnDataSourceFactory : public DbColumnDataSourceFactory {
  PqResultSource* result_source;
  const std::vector<DATA_TYPE> types;
  const int utcoffset;

public:
  PqColumnDataSourceFactory(PqResultSource* result_source_,
                            const std::vector<DATA_TYPE>& types_,
                            const int utcoffset_);
  virtual ~PqColumnDataSourceFactory();

public:
  virtual DbColumnDataSource* create(const int j);
};

#endif //RPOSTGRES_PQCOLUMNDATASOURCEFACTORY_H
