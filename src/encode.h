#ifndef __RPOSTGRES_ENCODE__
#define __RPOSTGRES_ENCODE__

// Defined in encode.cpp -------------------------------------------------------

void escape_in_buffer(const char* string, std::string& buffer);
void encode_in_buffer(cpp4r::sexp x, int i, std::string& buffer);
void encode_row_in_buffer(cpp4r::list x, int i, std::string& buffer,
                          std::string fieldDelim = "\t",
                          std::string lineDelim = "\n");
std::string encode_data_frame(cpp4r::list x);

#endif
