#ifndef DB_COLUMN_H
#define DB_COLUMN_H


#include "DbColumnDataType.h"
#include "DbColumnDataSourceFactory.h"
#include <boost/shared_ptr.hpp>
#include <boost/ptr_container/ptr_vector.hpp>

class DbColumnDataSourceFactory;
class DbColumnDataSource;
class DbColumnStorage;

class DbColumn {
private:
  boost::shared_ptr<DbColumnDataSource> source;
  boost::ptr_vector<DbColumnStorage> storage;
  int n;
  std::set<DATA_TYPE> data_types_seen;

public:
  DbColumn(DATA_TYPE dt_, const int n_max_, DbColumnDataSourceFactory* factory, const int j);
  ~DbColumn();

public:
  void set_col_value();
  void finalize(const int n_);
  void warn_type_conflicts(const String& name) const;

  operator SEXP() const;
  DATA_TYPE get_type() const;
  static const char* format_data_type(const DATA_TYPE dt);

private:
  DbColumnStorage* get_last_storage();
  const DbColumnStorage* get_last_storage() const;
};


#endif // DB_COLUMN_H
