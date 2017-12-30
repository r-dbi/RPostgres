#include "pch.h"
#include "DbColumnStorage.h"
#include "DbColumnDataSource.h"
#include "integer64.h"


using namespace Rcpp;

DbColumnStorage::DbColumnStorage(DATA_TYPE dt_, const R_xlen_t capacity_, const int n_max_,
                                 const DbColumnDataSource& source_)
  :
  i(0),
  dt(dt_),
  n_max(n_max_),
  source(source_)
{
  data = allocate(get_new_capacity(capacity_), dt);
}

DbColumnStorage::~DbColumnStorage() {
}

DbColumnStorage* DbColumnStorage::append_col() {
  if (source.is_null()) return append_null();
  return append_data();
}

DATA_TYPE DbColumnStorage::get_item_data_type() const {
  return source.get_data_type();
}

DATA_TYPE DbColumnStorage::get_data_type() const {
  if (dt == DT_UNKNOWN) return source.get_decl_data_type();
  return dt;
}

SEXP DbColumnStorage::allocate(const R_xlen_t length, DATA_TYPE dt) {
  SEXPTYPE type = sexptype_from_datatype(dt);
  RObject class_ = class_from_datatype(dt);

  SEXP ret = PROTECT(Rf_allocVector(type, length));
  if (!Rf_isNull(class_)) Rf_setAttrib(ret, R_ClassSymbol, class_);
  set_attribs_from_datatype(ret, dt);
  UNPROTECT(1);
  return ret;
}

int DbColumnStorage::copy_to(SEXP x, DATA_TYPE dt, const int pos) const {
  R_xlen_t n = Rf_xlength(x);
  int src, tgt;
  R_xlen_t capacity = get_capacity();
  for (src = 0, tgt = pos; src < capacity && src < i && tgt < n; ++src, ++tgt) {
    copy_value(x, dt, tgt, src);
  }

  for (; src < i && tgt < n; ++src, ++tgt) {
    fill_default_value(x, dt, tgt);
  }

  return src;
}

R_xlen_t DbColumnStorage::get_capacity() const {
  return Rf_xlength(data);
}

R_xlen_t DbColumnStorage::get_new_capacity(const R_xlen_t desired_capacity) const {
  if (n_max < 0) {
    const R_xlen_t MIN_DATA_CAPACITY = 100;
    return std::max(desired_capacity, MIN_DATA_CAPACITY);
  }
  else {
    return std::max(desired_capacity, R_xlen_t(1));
  }
}

DbColumnStorage* DbColumnStorage::append_null() {
  if (i < get_capacity()) fill_default_value();
  ++i;
  return this;
}

void DbColumnStorage::fill_default_value() {
  fill_default_value(data, dt, i);
}

DbColumnStorage* DbColumnStorage::append_data() {
  if (dt == DT_UNKNOWN) return append_data_to_new(dt);
  if (i >= get_capacity()) return append_data_to_new(dt);
  DATA_TYPE new_dt = source.get_data_type();
  if (dt == DT_INT && new_dt == DT_INT64) return append_data_to_new(DT_INT64);
  if (dt == DT_INT && new_dt == DT_REAL) return append_data_to_new(DT_REAL);

  fetch_value();
  ++i;
  return this;
}

DbColumnStorage* DbColumnStorage::append_data_to_new(DATA_TYPE new_dt) {
  if (new_dt == DT_UNKNOWN) new_dt = source.get_data_type();

  R_xlen_t desired_capacity = (n_max < 0) ? (get_capacity() * 2) : (n_max - i);

  DbColumnStorage* spillover = new DbColumnStorage(new_dt, desired_capacity, n_max, source);
  return spillover->append_data();
}

void DbColumnStorage::fetch_value() {
  switch (dt) {
  case DT_BOOL:
    LOGICAL(data)[i] = source.fetch_bool();
    break;

  case DT_INT:
    INTEGER(data)[i] = source.fetch_int();
    break;

  case DT_INT64:
    INTEGER64(data)[i] = source.fetch_int64();
    break;

  case DT_REAL:
    REAL(data)[i] = source.fetch_real();
    break;

  case DT_STRING:
    SET_STRING_ELT(data, i, source.fetch_string());
    break;

  case DT_BLOB:
    SET_VECTOR_ELT(data, i, source.fetch_blob());
    break;

  case DT_DATE:
    REAL(data)[i] = source.fetch_date();
    break;

  case DT_DATETIME:
    REAL(data)[i] = source.fetch_datetime_local();
    break;

  case DT_DATETIMETZ:
    REAL(data)[i] = source.fetch_datetime();
    break;

  case DT_TIME:
    REAL(data)[i] = source.fetch_time();
    break;

  default:
    stop("NYI");
  }
}

SEXPTYPE DbColumnStorage::sexptype_from_datatype(DATA_TYPE dt) {
  switch (dt) {
  case DT_UNKNOWN:
    return NILSXP;

  case DT_BOOL:
    return LGLSXP;

  case DT_INT:
    return INTSXP;

  case DT_INT64:
    return INT64SXP;

  case DT_REAL:
  case DT_DATE:
  case DT_DATETIME:
  case DT_DATETIMETZ:
  case DT_TIME:
    return REALSXP;

  case DT_STRING:
    return STRSXP;

  case DT_BLOB:
    return VECSXP;

  default:
    stop("Unknown type %d", dt);
  }
}

Rcpp::RObject DbColumnStorage::class_from_datatype(DATA_TYPE dt) {
  switch (dt) {
  case DT_INT64:
    return CharacterVector::create("integer64");

  case DT_BLOB:
    return CharacterVector::create("blob");

  case DT_DATE:
    return CharacterVector::create("Date");

  case DT_DATETIME:
  case DT_DATETIMETZ:
    return CharacterVector::create("POSIXct", "POSIXt");

  case DT_TIME:
    return CharacterVector::create("hms", "difftime");

  default:
    return R_NilValue;
  }
}

void DbColumnStorage::set_attribs_from_datatype(SEXP x, DATA_TYPE dt) {
  switch (dt) {
  case DT_TIME:
    Rf_setAttrib(x, PROTECT(CharacterVector::create("units")), PROTECT(CharacterVector::create("secs")));
    UNPROTECT(2);
    break;

  default:
    ;
  }
}

void DbColumnStorage::fill_default_value(SEXP data, DATA_TYPE dt, R_xlen_t i) {
  switch (dt) {
  case DT_BOOL:
    LOGICAL(data)[i] = NA_LOGICAL;
    break;

  case DT_INT:
    INTEGER(data)[i] = NA_INTEGER;
    break;

  case DT_INT64:
    INTEGER64(data)[i] = NA_INTEGER64;
    break;

  case DT_REAL:
  case DT_DATE:
  case DT_DATETIME:
  case DT_DATETIMETZ:
  case DT_TIME:
    REAL(data)[i] = NA_REAL;
    break;

  case DT_STRING:
    SET_STRING_ELT(data, i, NA_STRING);
    break;

  case DT_BLOB:
    SET_VECTOR_ELT(data, i, R_NilValue);
    break;

  case DT_UNKNOWN:
    stop("Not setting value for unknown data type");
  }
}

void DbColumnStorage::copy_value(SEXP x, DATA_TYPE dt, const int tgt, const int src) const {
  if (Rf_isNull(data)) {
    fill_default_value(x, dt, tgt);
  }
  else {
    switch (dt) {
    case DT_BOOL:
      LOGICAL(x)[tgt] = LOGICAL(data)[src];
      break;

    case DT_INT:
      INTEGER(x)[tgt] = INTEGER(data)[src];
      break;

    case DT_INT64:
      switch (TYPEOF(data)) {
      case INTSXP:
        INTEGER64(x)[tgt] = INTEGER(data)[src];
        break;

      case REALSXP:
        INTEGER64(x)[tgt] = INTEGER64(data)[src];
        break;
      }
      break;

    case DT_REAL:
      switch (TYPEOF(data)) {
      case INTSXP:
        REAL(x)[tgt] = INTEGER(data)[src];
        break;

      case REALSXP:
        REAL(x)[tgt] = REAL(data)[src];
        break;
      }
      break;

    case DT_STRING:
      SET_STRING_ELT(x, tgt, STRING_ELT(data, src));
      break;

    case DT_BLOB:
      SET_VECTOR_ELT(x, tgt, VECTOR_ELT(data, src));
      break;

    case DT_DATE:
    case DT_DATETIME:
    case DT_DATETIMETZ:
    case DT_TIME:
      REAL(x)[tgt] = REAL(data)[src];
      break;

    default:
      stop("NYI: default");
    }
  }
}
