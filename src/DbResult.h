#ifndef __RDBI_DB_RESULT__
#define __RDBI_DB_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>

#include "DbResultImplDecl.h"


class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

// DbResult --------------------------------------------------------------------

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;

protected:
  boost::scoped_ptr<DbResultImpl> impl;

protected:
  DbResult(const DbConnectionPtr& pConn);

public:
  ~DbResult();

public:
  void close();

  bool complete() const;
  bool is_active() const;
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const cpp11::list& params);
  cpp11::list fetch(int n_max = -1);

  cpp11::list get_column_info();

private:
  void validate_params(const cpp11::list& params) const;
};

#endif // __RDBI_DB_RESULT__
