#include "pch.h"
#include "PqResultImpl.h"
#include "DbConnection.h"
#include "DbResult.h"
#include "DbColumnStorage.h"
#include "PqDataFrame.h"

#ifdef _WIN32
#include <winsock2.h>
#endif

PqResultImpl::PqResultImpl(DbResult* pRes, PGconn* pConn, const std::string& sql, const bool check_interrupts) :
  res(pRes),
  pConn_(pConn),
  pSpec_(prepare(pConn, sql)),
  cache(pSpec_),
  complete_(false),
  ready_(false),
  data_ready_(false),
  check_interrupts_(check_interrupts),
  nrows_(0),
  rows_affected_(0),
  group_(0),
  groups_(0),
  pRes_(NULL)
{

  LOG_DEBUG << sql;

  try {
    if (cache.nparams_ == 0) {
      bind();
    }
  } catch (...) {
    PQclear(pSpec_);
    pSpec_ = NULL;
    throw;
  }
}

PqResultImpl::~PqResultImpl() {
  try {
    if (pSpec_) PQclear(pSpec_);
  } catch (...) {}
  if (pRes_) PQclear(pRes_);
}



// Cache ///////////////////////////////////////////////////////////////////////

PqResultImpl::_cache::_cache(PGresult* spec) :
  names_(get_column_names(spec)),
  oids_(get_column_oids(spec)),
  types_(get_column_types(oids_, names_)),
  known_(get_column_known(oids_)),
  ncols_(names_.size()),
  nparams_(PQnparams(spec))
{
  for (int i = 0; i < nparams_; ++i)
    LOG_VERBOSE << PQparamtype(spec, i);
}


std::vector<std::string> PqResultImpl::_cache::get_column_names(PGresult* spec) {
  std::vector<std::string> names;
  int ncols_ = PQnfields(spec);
  names.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    names.push_back(std::string(PQfname(spec, i)));
  }

  return names;
}

DATA_TYPE PqResultImpl::_cache::get_column_type_from_oid(const Oid type) {
  // SELECT oid, typname FROM pg_type WHERE typtype = 'b'
  switch (type) {
  case 20: // BIGINT
    return DT_INT64;
    break;

  case 21: // SMALLINT
  case 23: // INTEGER
  case 26: // OID
    return DT_INT;
    break;

  case 1700: // DECIMAL
  case 701: // FLOAT8
  case 700: // FLOAT
  case 790: // MONEY
    return DT_REAL;
    break;

  case 18: // CHAR
  case 19: // NAME
  case 25: // TEXT
  case 1042: // CHAR
  case 1043: // VARCHAR
    return DT_STRING;
    break;
  case 1082: // DATE
    return DT_DATE;
    break;
  case 1083: // TIME
  case 1266: // TIMETZOID
    return DT_TIME;
    break;
  case 1114: // TIMESTAMP
    return DT_DATETIME;
    break;
  case 1184: // TIMESTAMPTZOID
    return DT_DATETIMETZ;
    break;
  case 1186: // INTERVAL
  case 2950: // UUID
    return DT_STRING;
    break;

  case 16: // BOOL
    return DT_BOOL;
    break;

  case 17: // BYTEA
  case 2278: // NULL
    return DT_BLOB;
    break;

  case 705: // UNKNOWN
    return DT_STRING;
    break;

  default:
    return DT_UNKNOWN;
  }
}

std::vector<Oid> PqResultImpl::_cache::get_column_oids(PGresult* spec) {
  std::vector<Oid> oids;
  int ncols_ = PQnfields(spec);
  oids.reserve(ncols_);
  for (int i = 0; i < ncols_; ++i) {
    Oid oid = PQftype(spec, i);
    oids.push_back(oid);
  }
  return oids;
}

std::vector<DATA_TYPE> PqResultImpl::_cache::get_column_types(const std::vector<Oid>& oids, const std::vector<std::string>& names) {
  std::vector<DATA_TYPE> types;
  size_t ncols_ = oids.size();
  types.reserve(ncols_);

  for (size_t i = 0; i < ncols_; ++i) {
    Oid oid = oids[i];

    DATA_TYPE data_type = get_column_type_from_oid(oid);
    if (data_type == DT_UNKNOWN) {
      LOG_INFO << "Unknown field type (" << oid << ") in column " << names[i];
      data_type = DT_STRING;
    }

    types.push_back(data_type);
  }

  return types;
}

std::vector<bool> PqResultImpl::_cache::get_column_known(const std::vector<Oid>& oids) {
  std::vector<bool> known;
  size_t ncols_ = oids.size();
  known.reserve(ncols_);

  for (size_t i = 0; i < ncols_; ++i) {
    Oid oid = oids[i];

    DATA_TYPE data_type = get_column_type_from_oid(oid);
    known.push_back(data_type != DT_UNKNOWN);
  }

  return known;
}

PGresult* PqResultImpl::prepare(PGconn* conn, const std::string& sql) {
  // Prepare query
  PGresult* prep = PQprepare(conn, "", sql.c_str(), 0, NULL);
  if (PQresultStatus(prep) != PGRES_COMMAND_OK) {
    PQclear(prep);
    DbConnection::conn_stop(conn, "Failed to prepare query");
  }
  PQclear(prep);

  // Retrieve query specification
  PGresult* spec = PQdescribePrepared(conn, "");
  if (PQresultStatus(spec) != PGRES_COMMAND_OK) {
    PQclear(spec);
    DbConnection::conn_stop(conn, "Failed to retrieve query result metadata");
  }

  return spec;
}

void PqResultImpl::init(bool params_have_rows) {
  ready_ = true;
  nrows_ = 0;
  complete_ = !params_have_rows;
}



// Publics /////////////////////////////////////////////////////////////////////

bool PqResultImpl::complete() const {
  return complete_;
}

int PqResultImpl::n_rows_fetched() {
  return nrows_;
}

int PqResultImpl::n_rows_affected() {
  if (!ready_) return NA_INTEGER;
  if (cache.ncols_ > 0) return 0;
  return rows_affected_;
}

void PqResultImpl::bind(const List& params) {
  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  if (params.size() == 0 && ready_) {
    stop("Query does not require parameters.");
  }

  set_params(params);

  if (params.length() > 0) {
    SEXP first_col = params[0];
    groups_ = Rf_length(first_col);
  }
  else {
    groups_ = 1;
  }
  group_ = 0;

  rows_affected_ = 0;

  bool has_params = bind_row();
  after_bind(has_params);
}

List PqResultImpl::fetch(const int n_max) {
  if (!ready_)
    stop("Query needs to be bound before fetching");

  int n = 0;
  List out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  return out;
}

List PqResultImpl::get_column_info() {
  peek_first_row();

  CharacterVector names(cache.names_.begin(), cache.names_.end());

  CharacterVector types(cache.ncols_);
  for (size_t i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(DbColumnStorage::sexptype_from_datatype(cache.types_[i]));
  }

  List out = Rcpp::List::create(names, types, cache.oids_, cache.known_);
  out.attr("row.names") = IntegerVector::create(NA_INTEGER, -cache.ncols_);
  out.attr("class") = "data.frame";
  out.attr("names") = CharacterVector::create("name", "type", ".oid", ".known");

  return out;
}



// Publics (custom) ////////////////////////////////////////////////////////////




// Privates ////////////////////////////////////////////////////////////////////

void PqResultImpl::set_params(const List& params) {
  params_ = params;
}

bool PqResultImpl::bind_row() {
  LOG_VERBOSE << "groups: " << group_ << "/" << groups_;

  if (group_ >= groups_)
    return false;

  if (ready_ || group_ > 0) {
    DbConnection::finish_query(pConn_);
  }

  std::vector<const char*> c_params(cache.nparams_);
  std::vector<int> formats(cache.nparams_);
  std::vector<int> lengths(cache.nparams_);
  for (int i = 0; i < cache.nparams_; ++i) {
    if (TYPEOF(params_[i]) == VECSXP) {
      List param(params_[i]);
      if (!Rf_isNull(param[group_])) {
        Rbyte* param_value = RAW(param[group_]);
        c_params[i] = reinterpret_cast<const char*>(param_value);
        formats[i] = 1;
        lengths[i] = Rf_length(param[group_]);
      }
    }
    else {
      CharacterVector param(params_[i]);
      if (param[group_] != NA_STRING) {
        c_params[i] = CHAR(param[group_]);
      }
    }
  }

  // Pointer to first element of empty vector is undefined behavior!
  int success =
    cache.nparams_ ?
    PQsendQueryPrepared(pConn_, "", cache.nparams_, &c_params[0],
                        &lengths[0], &formats[0], 0) :
    PQsendQueryPrepared(pConn_, "", 0, NULL, NULL, NULL, 0);
  data_ready_ = false;

  if (!success)
    conn_stop("Failed to send query");

  if (!PQsetSingleRowMode(pConn_))
    conn_stop("Failed to set single row mode");

  return true;
}

void PqResultImpl::after_bind(bool params_have_rows) {
  init(params_have_rows);
  if (params_have_rows)
    step();
}

List PqResultImpl::fetch_rows(const int n_max, int& n) {
  n = (n_max < 0) ? 100 : n_max;

  PqDataFrame data(this, cache.names_, n_max, cache.types_);

  if (complete_ && data.get_ncols() == 0) {
    warning("Don't need to call dbFetch() for statements, only for queries");
  }

  while (!complete_) {
    LOG_VERBOSE << nrows_ << "/" << n;

    data.set_col_values();
    step();
    nrows_++;
    if (!data.advance())
      break;
  }

  LOG_VERBOSE << nrows_;
  List ret = data.get_data();
  add_oids(ret);
  return ret;
}

void PqResultImpl::step() {
  while (step_run())
    ;
}

bool PqResultImpl::step_run() {
  LOG_VERBOSE;

  if (pRes_) PQclear(pRes_);

  // Check user interrupts while waiting for the data to be ready
  if (!data_ready_) {
    wait_for_data();
    data_ready_ = true;
  }

  pRes_ = PQgetResult(pConn_);

  // We're done, but we need to call PQgetResult until it returns NULL
  if (PQresultStatus(pRes_) == PGRES_TUPLES_OK) {
    PGresult* next = PQgetResult(pConn_);
    while (next != NULL) {
      PQclear(next);
      next = PQgetResult(pConn_);
    }
  }

  if (pRes_ == NULL) {
    stop("No active query");
  }

  ExecStatusType status = PQresultStatus(pRes_);

  switch (status) {
  case PGRES_FATAL_ERROR:
    {
      PQclear(pRes_);
      pRes_ = NULL;
      conn_stop("Failed to fetch row");
      return false;
    }
  case PGRES_SINGLE_TUPLE:
    return false;
  default:
    return step_done();
  }
}

bool PqResultImpl::step_done() {
  char* tuples = PQcmdTuples(pRes_);
  rows_affected_ += atoi(tuples);

  ++group_;
  bool more_params = bind_row();

  if (!more_params)
    complete_ = true;

  LOG_VERBOSE << "group: " << group_ << ", more_params: " << more_params;
  return more_params;
}

List PqResultImpl::peek_first_row() {
  PqDataFrame data(this, cache.names_, 1, cache.types_);

  if (!complete_)
    data.set_col_values();
  // Not calling data.advance(), remains a zero-row data frame

  List ret = data.get_data();
  add_oids(ret);
  return ret;
}

void PqResultImpl::conn_stop(const char* msg) const {
  DbConnection::conn_stop(pConn_, msg);
}

void PqResultImpl::bind() {
  bind(List());
}

void PqResultImpl::add_oids(List& data) const {
  data.attr("oids") = cache.oids_;
  data.attr("known") = cache.known_;
}

PGresult* PqResultImpl::get_result() {
  return pRes_;
}

// checks user interrupts while waiting for the first row of data to be ready
// see https://www.postgresql.org/docs/current/static/libpq-async.html
void PqResultImpl::wait_for_data() {
  if (!check_interrupts_)
    return;

  int socket, ret;
  fd_set input;

  socket = PQsocket(pConn_);
  if (socket < 0) {
    stop("Failed to get connection socket");
  }
  FD_ZERO(&input);
  FD_SET(socket, &input);

  do {
    // wait for any traffic on the db connection socket but no longet then 1s
    timeval timeout = {0, 0};
    timeout.tv_sec = 1;

    const int nfds = socket + 1;
    ret = select(nfds, &input, NULL, NULL, &timeout);
    if (ret == 0) {
      // timeout reached - check user interrupt
      checkUserInterrupt();
    } else if(ret < 0) {
      stop("select() on the connection failed");
    }
    // update db connection state using data available on the socket
    if (!PQconsumeInput(pConn_)) {
      stop("Failed to consume input from the server");
    }
  } while (PQisBusy(pConn_)); // check if PQgetResult will still block
}
