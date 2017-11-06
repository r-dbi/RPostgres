#ifndef __RPOSTGRES_ENCODE__
#define __RPOSTGRES_ENCODE__

// Defined in encode.cpp -------------------------------------------------------

void escapeInBuffer(const char* string, std::string& buffer);
void encodeInBuffer(RObject x, int i, std::string& buffer);
void encodeRowInBuffer(List x, int i, std::string& buffer,
                       std::string fieldDelim = "\t",
                       std::string lineDelim = "\n");
std::string encode_data_frame(List x);

#endif
