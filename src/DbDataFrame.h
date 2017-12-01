#ifndef DB_DATAFRAME_H
#define DB_DATAFRAME_H

#include <boost/container/stable_vector.hpp>
#include <boost/scoped_ptr.hpp>
#include "DbColumnDataType.h"

class DbColumn;
class DbColumnDataSourceFactory;

class DbDataFrame {
  boost::scoped_ptr<DbColumnDataSourceFactory> factory;
  const int n_max;
  int i;
  boost::container::stable_vector<DbColumn> data;
  std::vector<std::string> names;

public:
  DbDataFrame(DbColumnDataSourceFactory* factory, std::vector<std::string> names, const int n_max_, const std::vector<DATA_TYPE>& types);
  virtual ~DbDataFrame();

public:
  void set_col_values();
  bool advance();

  List get_data();
  List get_data(std::vector<DATA_TYPE>& types);
  size_t get_ncols() const;

private:
  void finalize_cols();
};


#endif //DB_DATAFRAME_H
