#include "pch.h"
#include "PqResultImpl.h"
#include "DbConnection.h"
#include "DbResult.h"
#include "DbColumnStorage.h"
#include "PqDataFrame.h"

#ifdef _WIN32
#include <winsock2.h>
#define SOCKERR WSAGetLastError()
#define SOCKET_EINTR WSAEINTR
#else
#include <errno.h>
#define SOCKERR errno
#define SOCKET_EINTR EINTR
#endif

PqResultImpl::PqResultImpl(const DbConnectionPtr& pConn, const std::string& sql, bool immediate) :
  pConnPtr_(pConn),
  pConn_(pConn->conn()),
  sql_(sql),
  immediate_(immediate),
  pSpec_(NULL),
  complete_(false),
  ready_(false),
  data_ready_(false),
  nrows_(0),
  rows_affected_(0),
  group_(0),
  groups_(0),
  pRes_(NULL)
{

  LOG_DEBUG << sql;

  prepare();

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

PqResultImpl::_cache::_cache() :
  initialized_(false),
  ncols_(0),
  nparams_(0)
{
}

void PqResultImpl::_cache::set(PGresult* spec)
{
  // always: should be fast
  if (nparams_ == 0) {
    nparams_ = PQnparams(spec);
  }

  std::vector<std::string> new_names = get_column_names(spec);
  std::vector<Oid> new_oids = get_column_oids(spec);

  if (initialized_ || new_names.size() == 0) {
    LOG_VERBOSE;
    if (names_.size() != 0 && new_names.size() != 0 && names_ != new_names) {
      stop("Multiple queries must use the same column names.");
    }
    if (oids_.size() != 0 && new_oids.size() != 0 && oids_ != new_oids) {
      stop("Multiple queries must use the same column types.");
    }
    return;
  }

  initialized_ = true;
  names_ = new_names;
  oids_ = new_oids;
  types_ = get_column_types(oids_, names_);
  known_ = get_column_known(oids_);
  ncols_ = names_.size();

  LOG_DEBUG << nparams_;

  for (int i = 0; i < nparams_; ++i) {
    LOG_VERBOSE << PQparamtype(spec, i);
  }
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

void PqResultImpl::prepare() {
  if (immediate_) {
    return;
  }

  LOG_DEBUG << sql_;

  // Prepare query
  PGresult* prep = PQprepare(pConn_, "", sql_.c_str(), 0, NULL);
  if (PQresultStatus(prep) != PGRES_COMMAND_OK) {
    PQclear(prep);
    conn_stop("Failed to prepare query");
  }
  PQclear(prep);

  // Retrieve query specification
  PGresult* spec = PQdescribePrepared(pConn_, "");
  if (PQresultStatus(spec) != PGRES_COMMAND_OK) {
    PQclear(spec);
    conn_stop("Failed to retrieve query result metadata");
  }

  pSpec_ = spec;
  cache.set(spec);
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

void PqResultImpl::bind(const cpp11::list& params) {
  LOG_DEBUG << params.size();

  if (immediate_ && params.size() > 0) {
    stop("Immediate query cannot be parameterized.");
  }

  if (params.size() != cache.nparams_) {
    stop("Query requires %i params; %i supplied.",
         cache.nparams_, params.size());
  }

  if (params.size() == 0 && ready_) {
    stop("Query does not require parameters.");
  }

  set_params(params);

  if (params.size() > 0) {
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

cpp11::list PqResultImpl::fetch(const int n_max) {
  LOG_DEBUG << n_max;

  if (!ready_)
    stop("Query needs to be bound before fetching");

  int n = 0;
  cpp11::list out;

  if (n_max != 0)
    out = fetch_rows(n_max, n);
  else
    out = peek_first_row();

  return out;
}

cpp11::list PqResultImpl::get_column_info() {
  using namespace cpp11::literals;
  peek_first_row();

  cpp11::writable::strings names(cache.names_.size());
  auto it = cache.names_.begin();
  for (int i = 0; i < names.size(); i++, it++)
    names[i] = *it;

  cpp11::writable::strings types(cache.ncols_);
  for (size_t i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(DbColumnStorage::sexptype_from_datatype(cache.types_[i]));
  }

  return cpp11::list({
    "name"_nm = names,
    "type"_nm = types,
    ".oid"_nm = cache.oids_,
    ".known"_nm = cache.known_
  });
}



// Publics (custom) ////////////////////////////////////////////////////////////




// Privates ////////////////////////////////////////////////////////////////////

void PqResultImpl::set_params(const cpp11::list& params) {
  params_ = params;
}

bool PqResultImpl::bind_row() {
  LOG_VERBOSE << "groups: " << group_ << "/" << groups_;

  if (group_ >= groups_) {
    // Multi-statement support for immediate queries
    return immediate_;
  }

  if (ready_ || group_ > 0) {
    LOG_VERBOSE;
    DbConnection::finish_query(pConn_);
  }

  std::vector<const char*> c_params(cache.nparams_);
  std::vector<int> formats(cache.nparams_);
  std::vector<int> lengths(cache.nparams_);
  for (int i = 0; i < cache.nparams_; ++i) {
    if (TYPEOF(params_[i]) == VECSXP) {
      cpp11::list param(params_[i]);
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
  data_ready_ = false;

  if (immediate_) {
    int success = PQsendQuery(pConn_, sql_.c_str());

    if (!success) {
      conn_stop("Failed to send query");
    }
  }
  else {
    int success = PQsendQueryPrepared(
      pConn_, "", cache.nparams_,
      cache.nparams_ ? &c_params[0] : NULL,
      cache.nparams_ ? &lengths[0] : NULL,
      cache.nparams_ ? &formats[0] : NULL,
      0);

    if (!success)
      conn_stop("Failed to set query parameters");
  }

  if (!PQsetSingleRowMode(pConn_))
    conn_stop("Failed to set single row mode");

  return true;
}

void PqResultImpl::after_bind(bool params_have_rows) {
  init(params_have_rows);
  if (params_have_rows)
    step();
}

cpp11::list PqResultImpl::fetch_rows(const int n_max, int& n) {
  LOG_DEBUG << n_max << "/" << n;

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
  cpp11::writable::list ret = data.get_data();
  add_oids(ret);
  return ret;
}

void PqResultImpl::step() {
  LOG_VERBOSE;

  while (step_run())
    ;
}

bool PqResultImpl::step_run() {
  LOG_VERBOSE;

  if (pRes_) {
    PQclear(pRes_);
    pRes_ = NULL;
  }

  bool need_cache_reset = false;

  LOG_VERBOSE << data_ready_;

  // Check user interrupts while waiting for the data to be ready
  if (!data_ready_) {
    LOG_VERBOSE;

    bool proceed = wait_for_data();

    data_ready_ = true;

    if (!proceed) {
      pConnPtr_->cancel_query();
      complete_ = TRUE;
      stop("Interrupted.");
    }

    need_cache_reset = true;
  }

  pRes_ = PQgetResult(pConn_);

  LOG_VERBOSE;

  // We're done, but we need to call PQgetResult until it returns NULL
  if (PQresultStatus(pRes_) == PGRES_TUPLES_OK) {
    LOG_VERBOSE;

    step_done();
    return true;
  }

  if (pRes_ == NULL) {
    LOG_VERBOSE;

    complete_ = true;
    return false;
  }

  ExecStatusType status = PQresultStatus(pRes_);

  if (status == PGRES_FATAL_ERROR) {
    PQclear(pRes_);
    pRes_ = NULL;
    conn_stop("Failed to fetch row");
    return false;
  }

  if (need_cache_reset) {
    cache.set(pRes_);
  }

  if (status == PGRES_SINGLE_TUPLE) {
    LOG_VERBOSE;
    return false;
  }

  LOG_VERBOSE;
  return step_done();
}

bool PqResultImpl::step_done() {
  char* tuples = PQcmdTuples(pRes_);
  LOG_VERBOSE << tuples;
  rows_affected_ += atoi(tuples);
  LOG_VERBOSE << rows_affected_;

  ++group_;
  data_ready_ = false;

  bool more_params = bind_row();

  if (!more_params)
    complete_ = true;

  LOG_VERBOSE << "group: " << group_ << ", more_params: " << more_params;
  return more_params;
}

cpp11::list PqResultImpl::peek_first_row() {
  PqDataFrame data(this, cache.names_, 1, cache.types_);

  if (!complete_)
    data.set_col_values();
  // Not calling data.advance(), remains a zero-row data frame

  cpp11::writable::list ret = data.get_data();
  add_oids(ret);
  return ret;
}

void PqResultImpl::conn_stop(const char* msg) const {
  DbConnection::conn_stop(pConn_, msg);
}

void PqResultImpl::bind() {
  bind(cpp11::list());
}

void PqResultImpl::add_oids(cpp11::writable::list& data) const {
  data.attr("oids") = cpp11::as_sexp(cache.oids_);
  data.attr("known") = cpp11::as_sexp(cache.known_);

  auto is_without_tz = cpp11::writable::logicals(cache.types_.size());
  for (size_t i = 0; i < cache.types_.size(); ++i) {
    bool set = (cache.types_[i] == DT_DATETIME);
    LOG_VERBOSE << "is_without_tz[" << i << "]: " << set;
    is_without_tz[i] = set;
  }
  data.attr("without_tz") = is_without_tz;
}

PGresult* PqResultImpl::get_result() {
  return pRes_;
}

// checks user interrupts while waiting for the first row of data to be ready
// see https://www.postgresql.org/docs/current/static/libpq-async.html
// Returns `false` if an interrupt was detected
bool PqResultImpl::wait_for_data() {
  LOG_DEBUG << pConnPtr_->is_check_interrupts();

  if (!pConnPtr_->is_check_interrupts())
    return true;

  // update db connection state using data available on the socket
  if (!PQconsumeInput(pConn_)) {
    stop("Failed to consume input from the server");
  }

  // check if PQgetResult will block before waiting
  if (!PQisBusy(pConn_)) {
    return true;
  }

  int socket, ret;
  fd_set input;
  FD_ZERO(&input);

  socket = PQsocket(pConn_);
  if (socket < 0) {
    stop("Failed to get connection socket");
  }

  do {
    LOG_DEBUG;

    // wait for any traffic on the db connection socket but no longer than 1s
    timeval timeout = {0, 0};
    timeout.tv_sec = 1;
    FD_SET(socket, &input);

    const int nfds = socket + 1;
    ret = select(nfds, &input, NULL, NULL, &timeout);
    if (ret == 0) {
      LOG_DEBUG;

      // timeout reached - check user interrupt
      try {
        // FIXME: Do we even need this?
        checkUserInterrupt();
      }
      catch (...) {
        LOG_DEBUG;
        return false;
      }
    } else if (ret < 0) {
      // caught interrupt in select()
      if (SOCKERR == SOCKET_EINTR) {
        LOG_DEBUG;
        return false;
      } else {
        LOG_DEBUG;
        stop("select() failed with error code %d", SOCKERR);
      }
    }

    // update db connection state using data available on the socket
    if (!PQconsumeInput(pConn_)) {
      stop("Failed to consume input from the server");
    }
  } while (PQisBusy(pConn_)); // check if PQgetResult will still block

  return true;
}
