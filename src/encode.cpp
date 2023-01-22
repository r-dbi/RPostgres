#include "pch.h"
#include "encode.h"


[[cpp11::register]]
std::string encode_vector(cpp11::sexp x) {
  std::string buffer;

  int n = Rf_length(x);
  for (int i = 0; i < n; ++i) {
    encode_in_buffer(x, i, buffer);
    if (i != n - 1)
      buffer.push_back('\n');
  }

  return buffer;
}

void encode_row_in_buffer(cpp11::list x, int i, std::string& buffer,
                          std::string fieldDelim,
                          std::string lineDelim) {
  int p = Rf_length(x);
  for (int j = 0; j < p; ++j) {
    auto xj(x[j]);
    encode_in_buffer(xj, i, buffer);
    if (j != p - 1)
      buffer.append(fieldDelim);
  }
  buffer.append(lineDelim);
}

[[cpp11::register]]
std::string encode_data_frame(cpp11::list x) {
  if (Rf_length(x) == 0)
    return ("");
  int n = Rf_length(x[0]);

  std::string buffer;
  for (int i = 0; i < n; ++i) {
    encode_row_in_buffer(x, i, buffer);
  }

  return buffer;
}

// =============================================================================
// Derived from EncodeElementS in RPostgreSQL
// Written by: tomoakin@kenroku.kanazawa-u.ac.jp
// License: GPL-2

void encode_in_buffer(cpp11::sexp x, int i, std::string& buffer) {
  switch (TYPEOF(x)) {
  case LGLSXP:
    {
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
  case INTSXP:
    {
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
  case REALSXP:
    {
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
        char buf[17 + 1 + 1 + 4 + 1]; // minus + decimal + exponent + \0
        snprintf(buf, sizeof(buf), "%.17g", value);
        buffer.append(buf);
      }
      break;
    }
  case STRSXP:
    {
      RObject value = STRING_ELT(x, i);
      if (value == NA_STRING) {
        buffer.append("\\N");
      } else {
        const char* s = Rf_translateCharUTF8(STRING_ELT(x, i));
        escape_in_buffer(s, buffer);
      }
      break;
    }
  default:
    stop("Don't know how to handle vector of type %s.",
         Rf_type2char(TYPEOF(x)));
  }
}


// Escape postgresql special characters
// https://www.postgresql.org/docs/current/sql-copy.html
void escape_in_buffer(const char* string, std::string& buffer) {
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
