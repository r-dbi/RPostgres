#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/scoped_ptr.hpp>


class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

// DbResult --------------------------------------------------------------------
// There is no object analogous to DbResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResultImpl;

class DbResult : boost::noncopyable {
  DbConnectionPtr pConn_;
  boost::scoped_ptr<PqResultImpl> impl;

public:
  DbResult(const DbConnectionPtr& pConn, const std::string& sql);
  ~DbResult();

public:
  bool complete();
  bool active() const;
  int n_rows_fetched();
  int n_rows_affected();

  void bind(const List& params);
  List fetch(int n_max = -1);

  List get_column_info();

public:
  void finish_query();
};

#endif
