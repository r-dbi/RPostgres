#include "pch.h"
#include "PqResult.h"
#include "PqConnection.h"
#include "PqRow.h"


PqResult::PqResult(PqConnectionPtr pConn, std::string sql) :
  pConn_(pConn), nrows_(0), bound_(false) {
  pConn_->conCheck();
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
  names_ = columnNames();
  types_ = columnTypes();

}

PqResult::~PqResult() {
  try {
    if (active()) {
      PQclear(pSpec_);
      pConn_->setCurrentResult(NULL);
    }
  } catch (...) {}
}

void PqResult::bind() {
  bound_ = true;
  if (!PQsendQueryPrepared(pConn_->conn(), "", 0, NULL, NULL, NULL, 0))
    Rcpp::stop("Failed to send query");

  if (!PQsetSingleRowMode(pConn_->conn()))
    Rcpp::stop("Failed to set single row mode");
}

void PqResult::bind(Rcpp::List params) {
  if (params.size() != nparams_) {
    Rcpp::stop("Query requires %i params; %i supplied.",
               nparams_, params.size());
  }

  std::vector<const char*> c_params(nparams_);
  std::vector<int> c_formats(nparams_);
  std::vector<std::string> s_params(nparams_);
  for (int i = 0; i < nparams_; ++i) {
    Rcpp::CharacterVector param(params[i]);
    if (Rcpp::CharacterVector::is_na(param[0])) {
      c_params[i] = NULL;
      c_formats[i] = 0;
    } else {
      s_params[i] = Rcpp::as<std::string>(param[0]);
      c_params[i] = s_params[i].c_str();
      c_formats[i] = 0;
    }
  }

  if (!PQsendQueryPrepared(pConn_->conn(), "", nparams_, &c_params[0],
                           NULL, &c_formats[0], 0))
    Rcpp::stop("Failed to send query");

  if (!PQsetSingleRowMode(pConn_->conn()))
    Rcpp::stop("Failed to set single row mode");

  bound_ = true;
}

void PqResult::bindRows(Rcpp::List params) {
  if (params.size() != nparams_) {
    Rcpp::stop("Query requires %i params; %i supplied.",
               nparams_, params.size());
  }

  R_xlen_t n = Rcpp::CharacterVector(params[0]).size();

  std::vector<const char*> c_params(nparams_);
  std::vector<std::string> s_params(nparams_);
  std::vector<int> c_formats(nparams_);
  for (int j = 0; j < nparams_; ++j) {
    c_formats[j] = 0;
  }

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0)
      Rcpp::checkUserInterrupt();

    for (int j = 0; j < nparams_; ++j) {
      Rcpp::CharacterVector param(params[j]);
      s_params[j] = Rcpp::as<std::string>(param[i]);
      c_params[j] = s_params[j].c_str();
    }

    PGresult* res = PQexecPrepared(pConn_->conn(), "", nparams_,
                                   &c_params[0], NULL, &c_formats[0], 0);
    if (PQresultStatus(res) != PGRES_COMMAND_OK)
      Rcpp::stop("%s (row %i)", PQerrorMessage(pConn_->conn()), i + 1);
  }
}

bool PqResult::active() {
  return pConn_->isCurrentResult(this);
}

void PqResult::fetchRow() {
  pNextRow_.reset(new PqRow(pConn_->conn()));
  nrows_++;
}

void PqResult::fetchRowIfNeeded() {
  if (pNextRow_.get() != NULL)
    return;

  fetchRow();
}

Rcpp::List PqResult::fetch(int n_max) {
  if (!bound_)
    Rcpp::stop("Query needs to be bound before fetching");
  if (!active())
    Rcpp::stop("Inactive result set");

  int n = (n_max < 0) ? 100 : n_max;
  Rcpp::List out = dfCreate(types_, names_, n);

  int i = 0;
  fetchRowIfNeeded();
  while (pNextRow_->hasData()) {
    if (i >= n) {
      if (n_max < 0) {
        n *= 2;
        out = dfResize(out, n);
      } else {
        break;
      }
    }

    for (int j = 0; j < ncols_; ++j) {
      pNextRow_->setListValue(out[j], i, j, types_);
    }
    fetchRow();
    ++i;

    if (i % 1000 == 0)
      Rcpp::checkUserInterrupt();
  }

  // Trim back to what we actually used
  if (i < n) {
    out = dfResize(out, i);
  }
  for (int i = 0; i < out.size(); i++) {
    Rcpp::RObject col(out[i]);
    switch (types_[i]) {
    case PGDate:
      col.attr("class") = Rcpp::CharacterVector::create("Date");
      break;
    case PGDatetime:
    case PGDatetimeTZ:
      col.attr("class") = Rcpp::CharacterVector::create("POSIXct", "POSIXt");
      break;
    case PGTime:
      col.attr("class") = Rcpp::CharacterVector::create("hms", "difftime");
      col.attr("units") = Rcpp::CharacterVector::create("secs");
      break;
    default:
      break;
    }
  }
  return out;
}

int PqResult::rowsAffected() {
  fetchRowIfNeeded();
  return pNextRow_->rowsAffected();
}

int PqResult::rowsFetched() {
  return nrows_ - (pNextRow_.get() != NULL);
}

bool PqResult::isComplete() {
  fetchRowIfNeeded();
  return !pNextRow_->hasData();
}

Rcpp::List PqResult::columnInfo() {
  Rcpp::CharacterVector names(ncols_);
  for (int i = 0; i < ncols_; i++) {
    names[i] = names_[i];
  }

  Rcpp::CharacterVector types(ncols_);
  for (int i = 0; i < ncols_; i++) {
    switch (types_[i]) {
    case PGString:
      types[i] = "character";
      break;
    case PGInt:
      types[i] = "integer";
      break;
    case PGReal:
      types[i] = "double";
      break;
    case PGVector:
      types[i] = "list";
      break;
    case PGLogical:
      types[i] = "logical";
      break;
    case PGDate:
      types[i] = "Date";
      break;
    case PGDatetime:
      types[i] = "POSIXct";
      break;
    case PGDatetimeTZ:
      types[i] = "POSIXct";
      break;
    default:
      Rcpp::stop("Unknown variable type");
    }
  }

  Rcpp::List out = Rcpp::List::create(names, types);
  out.attr("row.names") = Rcpp::IntegerVector::create(NA_INTEGER, -ncols_);
  out.attr("class") = "data.frame";
  out.attr("names") = Rcpp::CharacterVector::create("name", "type");

  return out;
}

std::vector<std::string> PqResult::columnNames() const {
  std::vector<std::string> names;
  names.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    names.push_back(std::string(PQfname(pSpec_, i)));
  }

  return names;
}

std::vector<PGTypes> PqResult::columnTypes() const {
  std::vector<PGTypes> types;
  types.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    Oid type = PQftype(pSpec_, i);
    // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
    switch (type) {
    case 20: // BIGINT
    case 21: // SMALLINT
    case 23: // INTEGER
    case 26: // OID
      types.push_back(PGInt);
      break;

    case 1700: // DECIMAL
    case 701: // FLOAT8
    case 700: // FLOAT
    case 790: // MONEY
      types.push_back(PGReal);
      break;

    case 18: // CHAR
    case 19: // NAME
    case 25: // TEXT
    case 114: // JSON
    case 1042: // CHAR
    case 1043: // VARCHAR
      types.push_back(PGString);
      break;
    case 1082: // DATE
      types.push_back(PGDate);
      break;
    case 1083: // TIME
    case 1266: // TIMETZOID
      types.push_back(PGTime);
      break;
    case 1114: // TIMESTAMP
      types.push_back(PGDatetime);
      break;
    case 1184: // TIMESTAMPTZOID
      types.push_back(PGDatetimeTZ);
      break;
    case 1186: // INTERVAL
    case 3802: // JSONB
    case 2950: // UUID
      types.push_back(PGString);
      break;

    case 16: // BOOL
      types.push_back(PGLogical);
      break;

    case 17: // BYTEA
    case 2278: // NULL
      types.push_back(PGVector);
      break;

    default:
      types.push_back(PGString);
      Rcpp::warning("Unknown field type (%s) in column %s", type, PQfname(pSpec_, i));
    }
  }

  return types;
}
