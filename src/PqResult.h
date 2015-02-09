#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <Rcpp.h>
#include <libpq-fe.h>
#include <boost/noncopyable.hpp>
#include <boost/scoped_ptr.hpp>
#include "PqConnection.h"
#include "PqRow.h"
#include "PqUtils.h"

typedef boost::shared_ptr<PqRow> PqRowPtr;


// PqResult --------------------------------------------------------------------
// There is no object analogous to PqResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResult : boost::noncopyable {
  PqConnectionPtr pConn_;
  PqRowPtr pLastRow_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, rowsAffected_;

public:

  PqResult(PqConnectionPtr pConn, std::string sql): pConn_(pConn) {
    pConn->setCurrentResult(this);

    // Check for error here? Might be param mismatch
    PQsendQueryParams(pConn_->conn(), sql.c_str(), 0, NULL, NULL, NULL, NULL, 0);
    PQsetSingleRowMode(pConn_->conn());
  }

  ~PqResult() {
    try {
      if (active())
        pConn_->setCurrentResult(NULL);
    } catch (...) {}
  }

  bool active() {
    return pConn_->isCurrentResult(this);
  }

  void step() {
    pLastRow_.reset(new PqRow(pConn_->conn()));
    nrows_++;
  }

  void init() {
    if (pLastRow_.get() != NULL)
      return;

    step();

    rowsAffected_ = pLastRow_->rowsAffected();
    ncols_ = pLastRow_->ncols();
    names_ = pLastRow_->column_names();
    types_ = pLastRow_->column_types();
  }

  Rcpp::List fetch(int n_max = 10) {
    if (!active())
      Rcpp::stop("Inactive result set");

    init();
    Rcpp::List out = df_create(types_, n_max);
    int n = n_max;

    for(int i = 0; i < n_max; ++i) {
      if (pLastRow_->complete()) {
        n = i;
        break;
      }

      for (int j = 0; j < ncols_; ++j) {
        pLastRow_->set_list_value(out[j], i, j, types_[j]);
      }
      step();
    }

    if (n != n_max)
      out = df_resize(out, n);

    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -n);
    out.attr("class") = "data.frame";
    out.attr("names") = names_;

    return out;
  }

  int rowsAffected() {
    init();
    return rowsAffected_;
  }

  bool is_complete() {
    init();
    return pLastRow_->complete();
  }

  int nrows() {
    return nrows_;
  }

};

#endif
