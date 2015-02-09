#ifndef __RPOSTGRES_PQ_RESULT__
#define __RPOSTGRES_PQ_RESULT__

#include <Rcpp.h>
#include <libpq-fe.h>
#include <boost/noncopyable.hpp>
#include "PqConnection.h"
#include "PqRow.h"

// PqResult --------------------------------------------------------------------
// There is no object analogous to PqResult in libpq: this provides a result set
// like object for the R API. There is only ever one active result set (the
// most recent) for each connection.

class PqResult : boost::noncopyable {
  PqConnectionPtr pConn_;
  PqRow lastRow_;

public:

  PqResult(PqConnectionPtr pConn, std::string sql): pConn_(pConn), lastRow_(NULL) {
    pConn->setCurrentResult(this);

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

  Rcpp::List fetch(int n = 10) {
    for (int i = 0; i < n; ++i) {
      PqRow row(pConn_->conn());
      if (row.is_complete()) {
        break;
      }
    }
//
//     int p = PQnfields(pRes_);
//     Rcpp::List cols(p);
//     Rcpp::CharacterVector names(p);
//
//     for (int j = 0; j < p; ++j) {
//       Oid type = PQftype(pRes_, j);
//       std::string name(PQfname(pRes_, j));
//       SEXP col;
//
//       // These come from
//       // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
//       switch(type) {
//       case 20: // BIGINT
//       case 21: // SMALLINT
//       case 23: // INTEGER
//       case 26: // OID
//         col = int_fill_col(pRes_, j, rows_);
//         break;
//
//       case 1700: // DECIMAL
//       case 701: // FLOAT8
//       case 700: // FLOAT
//       case 790: // MONEY
//         col = real_fill_col(pRes_, j, rows_);
//         break;
//
//       case 18: // CHAR
//       case 19: // NAME
//       case 25: // TEXT
//       case 1042: // CHAR
//       case 1043: // VARCHAR
//       case 1082: // DATE
//       case 1083: // TIME
//       case 1114: // TIMESTAMP
//       case 1184: // TIMESTAMPTZOID
//       case 1186: // INTERVAL
//       case 1266: // TIMETZOID
//         col = str_fill_col(pRes_, j, rows_);
//         break;
//
//       case 16: // BOOL
//         col = lgl_fill_col(pRes_, j, rows_);
//         break;
//
//       case 17: // BYTEA
//       case 2278: // NULL
//       default:
//         col = str_fill_col(pRes_, j, rows_);
//
//         std::stringstream err;
//         err << "Unknown field type (" << type << ") in column " << name;
//         Rcpp::Function warning("warning");
//         warning(err.str());
//       }
//
//       cols[j] = col;
//       names[j] = name;
//     }
//
//     fetched_rows_ = rows_;
//
//     cols.names() = names;
//     cols.attr("class") = "data.frame";
//     cols.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -rows_);
//     return cols;
  }

  int rows_affected() {
//     pRes_check();
//     if (PQresultStatus(pRes_) != PGRES_COMMAND_OK)
//       Rcpp::stop("Not a data modifying query");
//     atoi(PQcmdTuples(pRes_));

    return 0;
  }

  bool is_complete() {
    return false;
  }



};

#endif
