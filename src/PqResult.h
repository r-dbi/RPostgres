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

  PqResult(PqConnectionPtr pConn, std::string sql): pConn_(pConn), nrows_(0) {
    pConn->setCurrentResult(this);

    try {
      if (!PQsendQueryParams(pConn_->conn(), sql.c_str(), 0, NULL, NULL, NULL, NULL, 0))
        Rcpp::stop(PQerrorMessage(pConn_->conn()));

      if (!PQsetSingleRowMode(pConn_->conn())) {
        Rcpp::stop("Failed to set single row mode");
      }

      fetch_row();
    } catch (...) {
      pConn->setCurrentResult(NULL);
      throw;
    }

    // Cache query metadata
    rowsAffected_ = pLastRow_->rowsAffected();
    ncols_ = pLastRow_->ncols();
    names_ = pLastRow_->column_names();
    types_ = pLastRow_->column_types();
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

  void fetch_row() {
    if (!active())
      Rcpp::stop("Inactive result set");

    pLastRow_.reset(new PqRow(pConn_->conn()));
    nrows_++;
  }

  Rcpp::List fetch(int n_max = -1) {
    int n = (n_max < 0) ? 100 : n_max;
    Rcpp::List out = df_create(types_, names_, n);

    int i = 0;
    while(pLastRow_->hasData()) {
      if (i >= n) {
        if (n_max < 0) {
          n *= 2;
          out = df_resize(out, n);
        } else {
          break;
        }
      }

      for (int j = 0; j < ncols_; ++j) {
        pLastRow_->set_list_value(out[j], i, j);
      }
      fetch_row();
      ++i;

      if (i % 1000 == 0)
        Rcpp::checkUserInterrupt();
    }

    // Trim back to what we actually used
    if (i < n) {
      out = df_resize(out, i);
    }

    return out;
  }

  Rcpp::List column_info() {
    Rcpp::CharacterVector names(ncols_);
    for (int i = 0; i < ncols_; i++) {
      names[i] = names_[i];
    }

    Rcpp::CharacterVector types(ncols_);
    for (int i = 0; i < ncols_; i++) {
      switch(types_[i]) {
      case STRSXP:  types[i] = "character"; break;
      case INTSXP:  types[i] = "integer"; break;
      case REALSXP: types[i] = "double"; break;
      case VECSXP:  types[i] = "list"; break;
      default: Rcpp::stop("Unknown variable type");
      }
    }

    Rcpp::List out = Rcpp::List::create(names, types);
    out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -ncols_);
    out.attr("class") = "data.frame";
    out.attr("names") = Rcpp::CharacterVector::create("name", "type");

    return out;
  }


  int rowsAffected() {
    return rowsAffected_;
  }

  bool is_complete() {
    return !pLastRow_->hasData();
  }

  int nrows() {
    return nrows_;
  }

};

#endif
