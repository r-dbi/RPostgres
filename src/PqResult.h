#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

#include "PqUtils.h"


class PqConnection;
typedef boost::shared_ptr<PqConnection> PqConnectionPtr;

class PqRow;
typedef boost::shared_ptr<PqRow> PqRowPtr;

// PqResult --------------------------------------------------------------------
// There is no object analogous to PqResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResult : boost::noncopyable {
  PqConnectionPtr pConn_;
  PGresult* pSpec_;
  PqRowPtr pNextRow_;
  std::vector<PGTypes> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, nparams_;
  bool bound_;

public:
  PqResult(PqConnectionPtr pConn, std::string sql);
  ~PqResult();

public:
  void bind();
  void bind(List params);
  void bindRows(List params);

  bool active();

  void fetchRow();
  void fetchRowIfNeeded();
  List fetch(int n_max = -1);

  int rowsAffected();
  int rowsFetched();
  bool isComplete();

  List columnInfo();

private:
  std::vector<std::string> columnNames() const;
  std::vector<PGTypes> columnTypes() const;
};

#endif
