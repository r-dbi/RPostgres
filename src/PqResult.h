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
    if (!active())
      Rcpp::stop("Inactive result set");

    if (pLastRow_.get() != NULL)
      return;

    nrows_ = 0;
    step();

    rowsAffected_ = pLastRow_->rowsAffected();
    ncols_ = pLastRow_->ncols();
    names_ = pLastRow_->column_names();
    types_ = pLastRow_->column_types();
  }

  Rcpp::List fetch(int n_max = 10) {
    init();

    int n = n_max;
    Rcpp::List out = df_create(types_, n);

    for(int i = 0; i < n_max; ++i) {
      if (pLastRow_->complete()) {
        n = i;
        break;
      }

      for (int j = 0; j < ncols_; ++j) {
        pLastRow_->set_list_value(out[j], i, j);
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

  Rcpp::List fetch_all() {
    init();

    int n = 100;
    Rcpp::List out = df_create(types_, n);

    int i = 0;
    while(!pLastRow_->complete()) {
      if (i >= n) {
        n *= 2;
        out = df_resize(out, n);
      }

      for (int j = 0; j < ncols_; ++j) {
        pLastRow_->set_list_value(out[j], i, j);
      }
      step();
      ++i;

      if (i % 1000 == 0)
        Rcpp::checkUserInterrupt();
    }

    // Trim back to what we actually used
    if (i < n) {
      out = df_resize(out, i);
    }

    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -i);
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
