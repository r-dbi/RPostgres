#include <Rcpp.h>
#include "PqUtils.h"
using namespace Rcpp;

// [[Rcpp::export]]
std::string encode_vector(RObject x) {
  std::string buffer;

  int n = Rf_length(x);
  for (int i = 0; i < n; ++i) {
    encodeInBuffer(x, i, buffer);
    if (i != n - 1)
      buffer.push_back('\n');
  }

  return buffer;
}

void encodeRowInBuffer(Rcpp::List x, int i, std::string& buffer,
                       std::string fieldDelim,
                       std::string lineDelim) {
  int p = Rf_length(x);
  for (int j = 0; j < p; ++j) {
    Rcpp::RObject xj(x[j]);
    encodeInBuffer(xj, i, buffer);
    if (j != p - 1)
      buffer.append(fieldDelim);
  }
  buffer.append(lineDelim);
}

// [[Rcpp::export]]
std::string encode_data_frame(List x) {
  if (Rf_length(x) == 0)
    return ("");
  int n = Rf_length(x[0]);

  std::string buffer;
  for (int i = 0; i < n; ++i) {
    encodeRowInBuffer(x, i, buffer);
  }

  return buffer;
}

// =============================================================================
// Derived from EncodeElementS in RPostgreSQL
// Written by: tomoakin@kenroku.kanazawa-u.ac.jp
// License: GPL-2

void encodeInBuffer(Rcpp::RObject x, int i, std::string& buffer) {
  switch (TYPEOF(x)) {
  case LGLSXP: {
    int value = LOGICAL(x)[i];
    if (value == TRUE) {
      buffer.append("true");
    } else if (value == FALSE) {
      buffer.append("false");
    } else {
      buffer.append("\\N");
    }
    break;
  }
  case INTSXP: {
    int value = INTEGER(x)[i];
    if (value == NA_INTEGER) {
      buffer.append("\\N");
    } else {
      char buf[32];
      snprintf(buf, 32, "%d", value);
      buffer.append(buf);
    }
    break;
  }
  case REALSXP: {
    double value = REAL(x)[i];
    if (!R_FINITE(value)) {
      if (ISNA(value)) {
        buffer.append("\\N");
      } else if (ISNAN(value)) {
        buffer.append("NaN");
      } else if (value > 0) {
        buffer.append("Infinity");
      } else {
        buffer.append("-Infinity");
      }
    } else {
      char buf[15 + 1 + 1 + 4 + 1]; // minus + decimal + exponent + \0
      snprintf(buf, 22, "%.15g", value);
      buffer.append(buf);
    }
    break;
  }
  case STRSXP: {
    RObject value = STRING_ELT(x, i);
    if (value == NA_STRING) {
      buffer.append("\\N");
    } else {
      const char* s = Rf_translateCharUTF8(STRING_ELT(x, i));
      escapeInBuffer(s, buffer);
    }
    break;
  }
  default:
    Rcpp::stop("Don't know how to handle vector of type %s.",
               Rf_type2char(TYPEOF(x)));
  }
}


// Escape postgresql special characters
// http://www.postgresql.org/docs/9.4/static/sql-copy.html#AEN71914
void escapeInBuffer(const char* string, std::string& buffer) {
  size_t len = strlen(string);

  for (size_t i = 0; i < len; ++i) {
    switch (string[i]) {
    case '\b':
      buffer.append("\\b");
      break;
    case '\f':
      buffer.append("\\f");
      break;
    case '\n':
      buffer.append("\\n");
      break;
    case '\r':
      buffer.append("\\r");
      break;
    case '\t':
      buffer.append("\\t");
      break;
    case '\v':
      buffer.append("\\v");
      break;
    case '\\':
      buffer.append("\\\\");
      break;
    default:
      buffer.push_back(string[i]);
    }
  }
}
