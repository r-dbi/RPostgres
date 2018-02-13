#include "pch.h"
#include "PqDataFrame.h"
#include "PqColumnDataSourceFactory.h"


PqDataFrame::PqDataFrame(PqResultSource* result_source,
                         const std::vector<std::string>& names,
                         const int n_max_,
                         const std::vector<DATA_TYPE>& types,
                         std::vector<Oid> oids) :
  DbDataFrame(new PqColumnDataSourceFactory(result_source, types), names, n_max_, types, oids)
{
}

PqDataFrame::~PqDataFrame() {
}
