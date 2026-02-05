#ifndef RPOSTGRES_PQDATAFRAME_H
#define RPOSTGRES_PQDATAFRAME_H

#include "DbDataFrame.h"

class PqResultSource;

class PqDataFrame : public DbDataFrame {
public:
  PqDataFrame(
    PqResultSource* result_source,
    const std::vector<std::string>& names,
    const int n_max_,
    const std::vector<DATA_TYPE>& types
  );
  ~PqDataFrame();
};

#endif  // RPOSTGRES_PQDATAFRAME_H
