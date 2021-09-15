#ifndef RPOSTGRES_PQRESULTIMPL_H
#define RPOSTGRES_PQRESULTIMPL_H

class PqResultImpl {
public:
  PqResultImpl();
  virtual ~PqResultImpl();

public:
  virtual void close() = 0;

  virtual void bind(const List& params) = 0;

  virtual List get_column_info() = 0;

  virtual List fetch(int n_max = -1) = 0;

  virtual int n_rows_affected() = 0;
  virtual int n_rows_fetched() = 0;
  virtual bool complete() = 0;
};

#endif //RPOSTGRES_PQRESULTIMPL_H
