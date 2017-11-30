#include "pch.h"
#include "PqResultImpl.h"
#include "DbConnection.h"
#include "PqRow.h"

PqResultImpl::PqResultImpl(PGconn* pConn, const std::string& sql) :
  pConn_(pConn), nrows_(0), ready_(false) {

  LOG_DEBUG << sql;

  // Prepare query
  PGresult* prep = PQprepare(pConn_, "", sql.c_str(), 0, NULL);
  if (PQresultStatus(prep) != PGRES_COMMAND_OK) {
    PQclear(prep);
    conn_stop("Failed to prepare query");
  }
  PQclear(prep);

  // Retrieve query specification
  pSpec_ = PQdescribePrepared(pConn_, "");
  if (PQresultStatus(pSpec_) != PGRES_COMMAND_OK) {
    PQclear(pSpec_);
    conn_stop("Failed to retrieve query result metadata");
  }

  // Find number of parameters, and auto bind if 0
  nparams_ = PQnparams(pSpec_);
  if (nparams_ == 0) {
    bind();
  }

  // Cache query metadata
  ncols_ = PQnfields(pSpec_);
  names_ = get_column_names();
  types_ = get_column_types();

}

PqResultImpl::~PqResultImpl() {
  try {
    PQclear(pSpec_);
  } catch (...) {}
}



// Publics /////////////////////////////////////////////////////////////////////

bool PqResultImpl::complete() {
  if (!ready_) return false;
  fetch_row_if_needed();
  return !pNextRow_->has_data();
}

int PqResultImpl::n_rows_fetched() {
  return nrows_ - (pNextRow_.get() != NULL);
}

int PqResultImpl::n_rows_affected() {
  if (!ready_) return NA_INTEGER;
  if (ncols_ > 0) return 0;
  fetch_row_if_needed();
  return pNextRow_->n_rows_affected();
}

void PqResultImpl::bind(const List& params) {
  if (params.size() != nparams_) {
    stop("Query requires %i params; %i supplied.",
         nparams_, params.size());
  }

  if (params.size() == 0 && ready_) {
    stop("dbBind() can only be called for queries or statements with parameters");
  }

  pNextRow_.reset();

  std::vector<const char*> c_params(nparams_);
  std::vector<int> formats(nparams_);
  std::vector<int> lengths(nparams_);
  for (int i = 0; i < nparams_; ++i) {
    if (TYPEOF(params[i]) == VECSXP) {
      List param(params[i]);
      if (!Rf_isNull(param[0])) {
        Rbyte* param_value = RAW(param[0]);
        c_params[i] = reinterpret_cast<const char*>(param_value);
        formats[i] = 1;
        lengths[i] = Rf_length(param[0]);
      }
    }
    else {
      CharacterVector param(params[i]);
      if (param[0] != NA_STRING) {
        c_params[i] = CHAR(param[0]);
      }
    }
  }

  if (!PQsendQueryPrepared(pConn_, "", nparams_, &c_params[0],
                           &lengths[0], &formats[0], 0))
    conn_stop("Failed to send query");

  if (!PQsetSingleRowMode(pConn_))
    conn_stop("Failed to set single row mode");

  ready_ = true;
}

List PqResultImpl::fetch(int n_max) {
  if (!ready_)
    stop("Query needs to be bound before fetching");

  int n = (n_max < 0) ? 100 : n_max;
  List out = df_create(types_, names_, n);

  int i = 0;
  fetch_row_if_needed();

  if (!pNextRow_->has_data() && out.length() == 0) {
    warning("Don't need to call dbFetch() for statements, only for queries");
  }

  while (pNextRow_->has_data()) {
    if (i >= n) {
      if (n_max < 0) {
        n *= 2;
        out = df_resize(out, n);
      } else {
        break;
      }
    }

    for (int j = 0; j < ncols_; ++j) {
      pNextRow_->set_list_value(out[j], i, j, types_);
    }
    fetch_row();
    ++i;

    if (i % 1000 == 0)
      checkUserInterrupt();
  }

  // Trim back to what we actually used
  if (i < n) {
    out = df_resize(out, i);
  }

  return finish_df(out);
}

List PqResultImpl::get_column_info() {
  CharacterVector names(ncols_);
  for (int i = 0; i < ncols_; i++) {
    names[i] = names_[i];
  }

  CharacterVector types(ncols_);
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
    case PGInt64:
      types[i] = "integer64";
      break;
    default:
      stop("Unknown variable type");
    }
  }

  List out = Rcpp::List::create(names, types);
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -ncols_);
  out.attr("class") = "data.frame";
  out.attr("names") = CharacterVector::create("name", "type");

  return out;
}



// Publics (custom) ////////////////////////////////////////////////////////////




// Privates ////////////////////////////////////////////////////////////////////

void PqResultImpl::bind() {
  bind(List());
}

void PqResultImpl::bind_rows(List params) {
  if (params.size() != nparams_) {
    stop("Query requires %i params; %i supplied.",
         nparams_, params.size());
  }

  R_xlen_t n = CharacterVector(params[0]).size();

  std::vector<const char*> c_params(nparams_);
  std::vector<std::string> s_params(nparams_);
  std::vector<int> c_formats(nparams_);
  for (int j = 0; j < nparams_; ++j) {
    c_formats[j] = 0;
  }

  for (int i = 0; i < n; ++i) {
    if (i % 1000 == 0)
      checkUserInterrupt();

    for (int j = 0; j < nparams_; ++j) {
      CharacterVector param(params[j]);
      // FIXME: Need PQescapeByteaConn for BYTEA
      s_params[j] = as<std::string>(param[i]);
      c_params[j] = s_params[j].c_str();
    }

    PGresult* res = PQexecPrepared(pConn_, "", nparams_,
                                   &c_params[0], NULL, &c_formats[0], 0);
    if (PQresultStatus(res) != PGRES_COMMAND_OK)
      conn_stop("Failed to execute prepared command");
  }
}

void PqResultImpl::fetch_row() {
  pNextRow_.reset(new PqRow(pConn_));
  nrows_++;
}

void PqResultImpl::fetch_row_if_needed() {
  if (pNextRow_.get() != NULL)
    return;

  fetch_row();
}

List PqResultImpl::finish_df(List out) const {
  for (int i = 0; i < out.size(); i++) {
    RObject col(out[i]);
    switch (types_[i]) {
    case PGDate:
      col.attr("class") = CharacterVector::create("Date");
      break;
    case PGDatetime:
    case PGDatetimeTZ:
      col.attr("class") = CharacterVector::create("POSIXct", "POSIXt");
      break;
    case PGTime:
      col.attr("class") = CharacterVector::create("hms", "difftime");
      col.attr("units") = CharacterVector::create("secs");
      break;
    case PGInt64:
      col.attr("class") = CharacterVector::create("integer64");
      break;
    default:
      break;
    }
  }
  return out;
}

std::vector<std::string> PqResultImpl::get_column_names() const {
  std::vector<std::string> names;
  names.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    names.push_back(std::string(PQfname(pSpec_, i)));
  }

  return names;
}

std::vector<PGTypes> PqResultImpl::get_column_types() const {
  std::vector<PGTypes> types;
  types.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    Oid type = PQftype(pSpec_, i);
    // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
    switch (type) {
    case 20: // BIGINT
      types.push_back(PGInt64);
      break;

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
      warning("Unknown field type (%d) in column %s", type, PQfname(pSpec_, i));
    }
  }

  return types;
}

void PqResultImpl::conn_stop(const char* msg) const {
  DbConnection::conn_stop(pConn_, msg);
}
