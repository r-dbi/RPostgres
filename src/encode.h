#ifndef __RPOSTGRES_ENCODE__
#define __RPOSTGRES_ENCODE__

// Defined in encode.cpp -------------------------------------------------------

void escape_in_buffer(const char* string, std::string& buffer);
void encode_in_buffer(cpp11::sexp x, int i, std::string& buffer);
void encode_row_in_buffer(
  cpp11::list x,
  int i,
  std::string& buffer,
  std::string fieldDelim = "\t",
  std::string lineDelim = "\n"
);
std::string encode_data_frame(cpp11::list x);

#endif
