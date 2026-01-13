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

  if (i % 1024 == 0)
    cpp4r::check_user_interrupt();

  return (n_max < 0 || i < n_max);
}

cpp4r::list DbDataFrame::get_data() {
  // Throws away new data types
  std::vector<DATA_TYPE> types_;
  return get_data(types_);
}

cpp4r::list DbDataFrame::get_data(std::vector<DATA_TYPE>& types_) {
  // Trim back to what we actually used
  finalize_cols();

  types_.clear();
  std::transform(data.begin(), data.end(), std::back_inserter(types_), boost::mem_fn(&DbColumn::get_type));

  boost::for_each(data, names, boost::bind(&DbColumn::warn_type_conflicts, _1, _2));

  cpp4r::writable::list out(data.size());
  auto it = data.begin();
  for (int i = 0; i < data.size(); i++) {
    out[i] = *it;
    it++;
  }
  auto names_utf8 = static_cast<cpp4r::writable::strings>(cpp4r::as_sexp(names));
  for (int j = 0; j < names_utf8.size(); ++j) {
    const auto name = static_cast<cpp4r::r_string>(names_utf8[j]);
    const auto name_str = static_cast<std::string>(name);
    names_utf8[j] = Rf_mkCharCE(name_str.c_str(), CE_UTF8);
  }
  out.attr("names") = names_utf8;
  out.attr("class") = "data.frame";
  out.attr("row.names") = cpp4r::integers({NA_INTEGER, -i});
  return out;
}

size_t DbDataFrame::get_ncols() const {
  return data.size();
}

void DbDataFrame::finalize_cols() {
  std::for_each(data.begin(), data.end(), boost::bind(&DbColumn::finalize, _1, i));
}
