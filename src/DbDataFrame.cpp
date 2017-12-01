#include "pch.h"
#include "DbDataFrame.h"
#include "DbColumn.h"
#include "DbColumnStorage.h"
#include "DbColumnDataSource.h"
#include "DbColumnDataSourceFactory.h"
#include <boost/bind.hpp>
#include <boost/range/algorithm_ext/for_each.hpp>

DbDataFrame::DbDataFrame(DbColumnDataSourceFactory* factory_, std::vector<std::string> names_, const int n_max_,
                         const std::vector<DATA_TYPE>& types_)
  : n_max(n_max_),
    i(0),
    names(names_)
{
  factory.reset(factory_);

  data.reserve(types_.size());
  for (size_t j = 0; j < types_.size(); ++j) {
    DbColumn x(types_[j], n_max, factory.get(), (int)j);
    data.push_back(x);
  }
}

DbDataFrame::~DbDataFrame() {
}

void DbDataFrame::set_col_values() {
  std::for_each(data.begin(), data.end(), boost::bind(&DbColumn::set_col_value, _1));
}

bool DbDataFrame::advance() {
  ++i;

  if (i % 1000 == 0)
    checkUserInterrupt();

  return (n_max < 0 || i < n_max);
}

List DbDataFrame::get_data() {
  // Throws away new data types
  std::vector<DATA_TYPE> types_;
  return get_data(types_);
}

List DbDataFrame::get_data(std::vector<DATA_TYPE>& types_) {
  // Trim back to what we actually used
  finalize_cols();

  types_.clear();
  std::transform(data.begin(), data.end(), std::back_inserter(types_), std::mem_fun_ref(&DbColumn::get_type));

  boost::for_each(data, names, boost::bind(&DbColumn::warn_type_conflicts, _1, _2));

  List out(data.begin(), data.end());
  out.attr("names") = names;
  out.attr("class") = "data.frame";
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -i);
  return out;
}

size_t DbDataFrame::get_ncols() const {
  return data.size();
}

void DbDataFrame::finalize_cols() {
  std::for_each(data.begin(), data.end(), boost::bind(&DbColumn::finalize, _1, i));
}
