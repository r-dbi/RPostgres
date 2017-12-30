#include "pch.h"
#include "DbColumn.h"
#include "DbColumnDataSource.h"
#include "DbColumnStorage.h"


DbColumn::DbColumn(DATA_TYPE dt, const int n_max_, DbColumnDataSourceFactory* factory, const int j)
  : source(factory->create(j)),
    n(0)
{
  if (dt == DT_BOOL)
    dt = DT_UNKNOWN;
  storage.push_back(new DbColumnStorage(dt, 0, n_max_, *source));
}

DbColumn::~DbColumn() {
}

void DbColumn::set_col_value() {
  DbColumnStorage* last = get_last_storage();
  DATA_TYPE dt = last->get_item_data_type();
  data_types_seen.insert(dt);

  DbColumnStorage* next = last->append_col();
  if (last != next) storage.push_back(next);
}

void DbColumn::finalize(const int n_) {
  n = n_;
}

void DbColumn::warn_type_conflicts(const String& name) const {
  std::set<DATA_TYPE> my_data_types_seen = data_types_seen;
  DATA_TYPE dt = get_last_storage()->get_data_type();

  switch (dt) {
  case DT_REAL:
    my_data_types_seen.erase(DT_INT);
    break;

  case DT_INT64:
    my_data_types_seen.erase(DT_INT);
    break;

  default:
    break;
  }

  my_data_types_seen.erase(DT_UNKNOWN);
  my_data_types_seen.erase(DT_BOOL);
  my_data_types_seen.erase(dt);

  if (my_data_types_seen.size() == 0) return;

  String name_utf8 = name;
  name_utf8.set_encoding(CE_UTF8);

  std::stringstream ss;
  ss << "Column `" << name_utf8.get_cstring() << "`: " <<
     "mixed type, first seen values of type " << format_data_type(dt) << ", " <<
     "coercing other values of type ";

  bool first = true;
  for (std::set<DATA_TYPE>::const_iterator it = my_data_types_seen.begin(); it != my_data_types_seen.end(); ++it) {
    if (!first) ss << ", ";
    else first = false;
    ss << format_data_type(*it);
  }

  warning(ss.str());
}

DbColumn::operator SEXP() const {
  DATA_TYPE dt = get_last_storage()->get_data_type();
  SEXP ret = PROTECT(DbColumnStorage::allocate(n, dt));
  int pos = 0;
  for (size_t k = 0; k < storage.size(); ++k) {
    const DbColumnStorage& current = storage[k];
    pos += current.copy_to(ret, dt, pos);
  }
  UNPROTECT(1);
  return ret;
}

DATA_TYPE DbColumn::get_type() const {
  const DATA_TYPE dt = get_last_storage()->get_data_type();
  return dt;
}

const char* DbColumn::format_data_type(const DATA_TYPE dt) {
  switch (dt) {
  case DT_UNKNOWN:
    return "unknown";
  case DT_BOOL:
    return "boolean";
  case DT_INT:
    return "integer";
  case DT_INT64:
    return "integer64";
  case DT_REAL:
    return "real";
  case DT_STRING:
    return "string";
  case DT_BLOB:
    return "blob";
  default:
    return "<unknown type>";
  }
}

DbColumnStorage* DbColumn::get_last_storage() {
  return &storage.end()[-1];
}

const DbColumnStorage* DbColumn::get_last_storage() const {
  return &storage.end()[-1];
}
