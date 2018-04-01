#include "pch.h"
#include "PqUtils.h"

// From https://stackoverflow.com/a/40914871/946850:
int days_from_civil(int y, int m, int d) {
  y -= m <= 2;
  const int era = (y >= 0 ? y : y - 399) / 400;
  const int yoe = static_cast<unsigned>(y - era * 400);           // [0, 399]
  const int doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1; // [0, 365]
  const int doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;          // [0, 146096]
  return era * 146097 + doe - 719468;
}

time_t tm_to_time_t(const tm& tm_) {
  const time_t days = days_from_civil(tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday);
  return days * 86400 + tm_.tm_hour * 60 * 60 + tm_.tm_min * 60 + tm_.tm_sec;
}
