#include "pch.h"
#include <boost/lexical_cast.hpp>
#include "PqColumnDataSource.h"
#include "PqResultSource.h"
#include "PqUtils.h"

PqColumnDataSource::PqColumnDataSource(PqResultSource* result_source_, const DATA_TYPE dt_, const int j) :
  DbColumnDataSource(j),
  result_source(result_source_),
  dt(dt_)
{
}

PqColumnDataSource::~PqColumnDataSource() {
}

DATA_TYPE PqColumnDataSource::get_data_type() const {
  return dt;
}

DATA_TYPE PqColumnDataSource::get_decl_data_type() const {
  return dt;
}

bool PqColumnDataSource::is_null() const {
  LOG_VERBOSE;
  return PQgetisnull(get_result(), 0, get_j()) != 0;
}

int PqColumnDataSource::fetch_bool() const {
  LOG_VERBOSE;
  return (strcmp(get_result_value(), "t") == 0);
}


int PqColumnDataSource::fetch_int() const {
  LOG_VERBOSE;
  return atoi(get_result_value());
}

int64_t PqColumnDataSource::fetch_int64() const {
  LOG_VERBOSE;
  return boost::lexical_cast<int64_t>(get_result_value());
}

double PqColumnDataSource::fetch_real() const {
  LOG_VERBOSE;
  return atof(get_result_value());
}

SEXP PqColumnDataSource::fetch_string() const {
  LOG_VERBOSE;
  return Rf_mkCharCE(get_result_value(), CE_UTF8);
}

SEXP PqColumnDataSource::fetch_blob() const {
  LOG_VERBOSE;
  const void* val = get_result_value();

  size_t to_length = 0;
  unsigned char* unescaped_blob = PQunescapeBytea(static_cast<const unsigned char*>(val), &to_length);

  SEXP bytes = Rf_allocVector(RAWSXP, static_cast<R_xlen_t>(to_length));
  memcpy(RAW(bytes), unescaped_blob, to_length);

  PQfreemem(unescaped_blob);

  return bytes;
}

double PqColumnDataSource::fetch_date() const {
  LOG_VERBOSE;
  const char* val = get_result_value();
  int year = *val - 0x30;
  year *= 10;
  year += (*(++val) - 0x30);
  year *= 10;
  year += (*(++val) - 0x30);
  year *= 10;
  year += (*(++val) - 0x30);
  val++;
  int mon = 10 * (*(++val) - 0x30);
  mon += (*(++val) - 0x30);
  val++;
  int mday = (*(++val) - 0x30) * 10;
  mday += (*(++val) - 0x30);
  return days_from_civil(year, mon, mday);
}

double PqColumnDataSource::fetch_datetime_local() const {
  LOG_VERBOSE;
  return convert_datetime(get_result_value(), true);
}

double PqColumnDataSource::fetch_datetime() const {
  LOG_VERBOSE;
  return convert_datetime(get_result_value(), false);
}

double PqColumnDataSource::fetch_time() const {
  LOG_VERBOSE;
  const char* val = get_result_value();
  int hour = (*val - 0x30) * 10;
  hour += (*(++val) - 0x30);
  val++;
  int min = (*(++val) - 0x30) * 10;
  min += (*(++val) - 0x30);
  val++;
  double sec = strtod(++val, NULL);
  return static_cast<double>(hour * 3600 + min * 60) + sec;
}

double PqColumnDataSource::convert_datetime(const char* val, bool use_local) {
  char* end;
  struct tm date;
  date.tm_isdst = -1;
  date.tm_year = *val++ - 0x30;
  date.tm_year *= 10;
  date.tm_year += (*val++ - 0x30);
  date.tm_year *= 10;
  date.tm_year += (*val++ - 0x30);
  date.tm_year *= 10;
  date.tm_year += (*val++ - 0x30) - 1900;
  LOG_VERBOSE << date.tm_year;

  val++;
  date.tm_mon = (*val++ - 0x30) * 10;
  date.tm_mon += (*val++ - 0x30) - 1;
  LOG_VERBOSE << date.tm_mon;

  val++;
  date.tm_mday = (*val++ - 0x30) * 10;
  date.tm_mday += (*val++ - 0x30);
  LOG_VERBOSE << date.tm_mday;

  val++;
  date.tm_hour = (*val++ - 0x30) * 10;
  date.tm_hour += (*val++ - 0x30);
  LOG_VERBOSE << date.tm_hour;

  val++;
  date.tm_min = (*val++ - 0x30) * 10;
  date.tm_min += (*val++ - 0x30);
  LOG_VERBOSE << date.tm_min;

  val++;
  char* end;
  double sec = strtod(val, &end);
  val = end;
  LOG_VERBOSE << sec;

  date.tm_sec = static_cast<int>(sec);
  LOG_VERBOSE << date.tm_sec;

  int utcoffset = 0;
  if (*val == '+' || *val == '-') {
    int tz_hours = 0, tz_minutes = 0, sign = 0;
    sign = (*val++ == '+' ? +1 : -1);
    tz_hours = (*val++ - 0x30) * 10;
    tz_hours += (*val++ - 0x30);

    if (*val == ':') {
      tz_minutes = (*val++ - 0x30) * 10;
      tz_minutes += (*val++ - 0x30);
    }

    utcoffset = sign * (tz_hours * 3600 + tz_minutes * 60);
  }

  time_t time = tm_to_time_t(date);
  LOG_VERBOSE << time;

  double ret = static_cast<double>(time) + (sec - date.tm_sec) - utcoffset;
  LOG_VERBOSE << ret;

  return ret;
}

PGresult* PqColumnDataSource::get_result() const {
  return result_source->get_result();
}

const char* PqColumnDataSource::get_result_value() const {
  const char* val = PQgetvalue(get_result(), 0, get_j());
  LOG_VERBOSE << val;
  return val;
}
