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
  PGresult* pSpec_;
  std::vector<SEXPTYPE> types_;
  std::vector<std::string> names_;
  int ncols_, nrows_, rowsAffected_, nparams_;
  bool bound_;

public:

  PqResult(PqConnectionPtr pConn, std::string sql):
           pConn_(pConn), nrows_(0), bound_(false) {
    pConn_->con_check();
    pConn->setCurrentResult(this);

    try {
      // Prepare query
      PGresult* prep = PQprepare(pConn_->conn(), "", sql.c_str(), 0, NULL);
      if (PQresultStatus(prep) != PGRES_COMMAND_OK) {
        PQclear(prep);
        Rcpp::stop(PQerrorMessage(pConn_->conn()));
      }
      PQclear(prep);

      // Retrieve query specification
      pSpec_ = PQdescribePrepared(pConn_->conn(), "");
      if (PQresultStatus(pSpec_) != PGRES_COMMAND_OK) {
        PQclear(pSpec_);
        Rcpp::stop(PQerrorMessage(pConn_->conn()));
      }

      // Find number of parameters, and auto bind if 0
      nparams_ = PQnparams(pSpec_);
      if (nparams_ == 0) {
        bind();
      }

    } catch (...) {
      pConn->setCurrentResult(NULL);
      throw;
    }

    // Cache query metadata
    ncols_ = PQnfields(pSpec_);
    names_ = column_names();
    types_ = column_types();

  }

  ~PqResult() {
    try {
      if (active())
        PQclear(pSpec_);
        pConn_->setCurrentResult(NULL);
    } catch (...) {}
  }

  void bind() {
    bound_ = true;
    if (!PQsendQueryPrepared(pConn_->conn(), "", 0, NULL, NULL, NULL, 0))
      Rcpp::stop("Failed to send query");

    if (!PQsetSingleRowMode(pConn_->conn()))
      Rcpp::stop("Failed to set single row mode");
  }

  void bind(Rcpp::ListOf<Rcpp::CharacterVector> params) {
    if (params.size() != nparams_) {
      Rcpp::stop("Query requires %i params; %i supplied.",
        nparams_, params.size());
    }

    std::vector<const char*> c_params(nparams_);
    std::vector<int> c_formats(nparams_);
    for (int i = 0; i < nparams_; ++i) {
      std::string param(params[i][0]);
      c_params[i] = param.c_str();
      c_formats[i] = 0;
    }

    if (!PQsendQueryPrepared(pConn_->conn(), "", nparams_, &c_params[0],
         NULL, &c_formats[0], 0))
      Rcpp::stop("Failed to send query");

    if (!PQsetSingleRowMode(pConn_->conn()))
      Rcpp::stop("Failed to set single row mode");

    bound_ = true;
  }

  bool active() {
    return pConn_->isCurrentResult(this);
  }

  Rcpp::List fetch(int n_max = -1) {
    if (!bound_)
      Rcpp::stop("Query needs to be bound before fetching");
    if (!active())
      Rcpp::stop("Inactive result set");

    PqRowPtr pRow(new PqRow(pConn_->conn()));
    nrows_++;

    int n = (n_max < 0) ? 100 : n_max;
    Rcpp::List out = df_create(types_, names_, n);

    int i = 0;
    while(pRow->hasData()) {
      if (i >= n) {
        if (n_max < 0) {
          n *= 2;
          out = df_resize(out, n);
        } else {
          break;
        }
      }

      for (int j = 0; j < ncols_; ++j) {
        pRow->set_list_value(out[j], i, j);
      }
      pRow.reset(new PqRow(pConn_->conn()));
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

  int rowsAffected() {
    return -1;
  }

  bool is_complete() {
    return false;
  }

  int nrows() {
    return nrows_;
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

private:
  std::vector<std::string> column_names() const {
    std::vector<std::string> names;
    names.reserve(ncols_);

    for (int i = 0; i < ncols_; ++i) {
      names.push_back(std::string(PQfname(pSpec_, i)));
    }

    return names;
  }

  std::vector<SEXPTYPE> column_types() const {
    std::vector<SEXPTYPE> types;
    types.reserve(ncols_);

    for (int i = 0; i < ncols_; ++i) {
      Oid type = PQftype(pSpec_, i);
      // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
      switch(type) {
      case 20: // BIGINT
      case 21: // SMALLINT
      case 23: // INTEGER
      case 26: // OID
        types.push_back(INTSXP);
        break;

      case 1700: // DECIMAL
      case 701: // FLOAT8
      case 700: // FLOAT
      case 790: // MONEY
        types.push_back(REALSXP);
        break;

      case 18: // CHAR
      case 19: // NAME
      case 25: // TEXT
      case 1042: // CHAR
      case 1043: // VARCHAR
      case 1082: // DATE
      case 1083: // TIME
      case 1114: // TIMESTAMP
      case 1184: // TIMESTAMPTZOID
      case 1186: // INTERVAL
      case 1266: // TIMETZOID
        types.push_back(STRSXP);
        break;

      case 16: // BOOL
        types.push_back(LGLSXP);
        break;

      case 17: // BYTEA
      case 2278: // NULL
        types.push_back(VECSXP);
        break;

      default:
        types.push_back(STRSXP);
      Rcpp::warning("Unknown field type (%s) in column %i", type, i);
      }
    }

    return types;
  }


};

#endif
