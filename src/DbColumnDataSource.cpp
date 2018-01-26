#include "pch.h"
#include "DbColumnDataSource.h"

DbColumnDataSource::DbColumnDataSource(const int j_) :
  j(j_)
{
}

DbColumnDataSource::~DbColumnDataSource() {
}

int DbColumnDataSource::get_j() const {
  return j;
}
