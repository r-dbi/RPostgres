#include "pch.h"
#include "PqColumnDataSourceFactory.h"
#include "PqColumnDataSource.h"

PqColumnDataSourceFactory::PqColumnDataSourceFactory(PqResultSource* result_source_,
                                                     const std::vector<DATA_TYPE>& types_,
                                                     const int utcoffset_) :
  result_source(result_source_),
  types(types_),
  utcoffset(utcoffset_)
{
}

PqColumnDataSourceFactory::~PqColumnDataSourceFactory() {
}

DbColumnDataSource* PqColumnDataSourceFactory::create(const int j) {
  return new PqColumnDataSource(result_source, types[j], j, utcoffset);
}
