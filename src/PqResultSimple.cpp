#include "pch.h"
#include "PqResultSimple.h"
#include "DbConnection.h"
#include "DbResult.h"
#include "DbColumnStorage.h"
#include "PqDataFrame.h"

#ifdef _WIN32
#include <winsock2.h>
#define SOCKERR WSAGetLastError()
#else
#define SOCKERR errno
#endif

PqResultSimple::PqResultSimple(const DbConnectionPtr& pConn, const std::string& sql) :
  pConnPtr_(pConn),
  pConn_(pConn->conn()),
  pSpec_(prepare(pConn_, sql)),
  cache(pSpec_),
  complete_(false),
  ready_(false),
  data_ready_(false),
  nrows_(0),
  rows_affected_(0),
  pRes_(NULL)
{

  LOG_DEBUG << sql;

  try {
    bind();
  } catch (...) {
    PQclear(pSpec_);
    pSpec_ = NULL;
    throw;
  }
}

PqResultSimple::~PqResultSimple() {
  try {
    if (pSpec_) PQclear(pSpec_);
  } catch (...) {}
  if (pRes_) PQclear(pRes_);
}



// Cache ///////////////////////////////////////////////////////////////////////

PqResultSimple::_cache::_cache(PGresult* spec) :
  names_(get_column_names(spec)),
  oids_(get_column_oids(spec)),
  types_(get_column_types(oids_, names_)),
  known_(get_column_known(oids_)),
  ncols_(names_.size())
{
}


std::vector<std::string> PqResultSimple::_cache::get_column_names(PGresult* spec) {
  std::vector<std::string> names;
  int ncols_ = PQnfields(spec);
  names.reserve(ncols_);

  for (int i = 0; i < ncols_; ++i) {
    names.push_back(std::string(PQfname(spec, i)));
  }

  return names;
}

DATA_TYPE PqResultSimple::_cache::get_column_type_from_oid(const Oid type) {
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

std::vector<Oid> PqResultSimple::_cache::get_column_oids(PGresult* spec) {
  std::vector<Oid> oids;
  int ncols_ = PQnfields(spec);
  oids.reserve(ncols_);
  for (int i = 0; i < ncols_; ++i) {
    Oid oid = PQftype(spec, i);
    oids.push_back(oid);
  }
  return oids;
}

std::vector<DATA_TYPE> PqResultSimple::_cache::get_column_types(const std::vector<Oid>& oids, const std::vector<std::string>& names) {
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

std::vector<bool> PqResultSimple::_cache::get_column_known(const std::vector<Oid>& oids) {
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

PGresult* PqResultSimple::prepare(PGconn* conn, const std::string& sql) {
  // Execute query
  PGresult* spec = PQexec(conn, sql.c_str());
  if (PQresultStatus(spec) != PGRES_COMMAND_OK) {
    PQclear(spec);
    DbConnection::conn_stop(conn, "Failed to execute query");
  }

  return spec;
}

void PqResultSimple::init(bool params_have_rows) {
  ready_ = true;
  nrows_ = 0;
  complete_ = !params_have_rows;
}



// Publics /////////////////////////////////////////////////////////////////////

void PqResultSimple::close() {
  // FIXME
}

void PqResultSimple::bind(const List&) {
}

List PqResultSimple::get_column_info() {
  peek_first_row();

  CharacterVector names(cache.names_.begin(), cache.names_.end());

  CharacterVector types(cache.ncols_);
  for (size_t i = 0; i < cache.ncols_; i++) {
    types[i] = Rf_type2char(DbColumnStorage::sexptype_from_datatype(cache.types_[i]));
  }

  return Rcpp::List::create(
    _["name"] = names,
    _["type"] = types,
    _[".oid"] = cache.oids_,
    _[".known"] = cache.known_
  );
}

List PqResultSimple::fetch(const int n_max) {
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

int PqResultSimple::n_rows_fetched() {
  return nrows_;
}

int PqResultSimple::n_rows_affected() {
  if (!ready_) return NA_INTEGER;
  if (cache.ncols_ > 0) return 0;
  return rows_affected_;
}

bool PqResultSimple::complete() {
  return complete_;
}



// Publics (custom) ////////////////////////////////////////////////////////////




// Privates ////////////////////////////////////////////////////////////////////

List PqResultSimple::fetch_rows(const int n_max, int& n) {
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

void PqResultSimple::step() {
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
      return;
    }
  case PGRES_SINGLE_TUPLE:
    return;
  default:
    step_done();
    return;
  }
}

void PqResultSimple::step_done() {
  char* tuples = PQcmdTuples(pRes_);
  rows_affected_ = atoi(tuples);
  complete_ = true;
}

List PqResultSimple::peek_first_row() {
  PqDataFrame data(this, cache.names_, 1, cache.types_);

  if (!complete_)
    data.set_col_values();
  // Not calling data.advance(), remains a zero-row data frame

  List ret = data.get_data();
  add_oids(ret);
  return ret;
}

void PqResultSimple::conn_stop(const char* msg) const {
  DbConnection::conn_stop(pConn_, msg);
}

void PqResultSimple::bind() {
  bind(List());
}

void PqResultSimple::add_oids(List& data) const {
  data.attr("oids") = cache.oids_;
  data.attr("known") = cache.known_;

  LogicalVector is_without_tz = LogicalVector(cache.types_.size());
  for (size_t i = 0; i < cache.types_.size(); ++i) {
    bool set = (cache.types_[i] == DT_DATETIME);
    LOG_VERBOSE << "is_without_tz[" << i << "]: " << set;
    is_without_tz[i] = set;
  }
  data.attr("without_tz") = is_without_tz;
}

PGresult* PqResultSimple::get_result() {
  return pRes_;
}

// checks user interrupts while waiting for the first row of data to be ready
// see https://www.postgresql.org/docs/current/static/libpq-async.html
void PqResultSimple::wait_for_data() {
  if (!pConnPtr_->is_check_interrupts())
    return;

  int socket, ret;
  fd_set input;
  FD_ZERO(&input);

  socket = PQsocket(pConn_);
  if (socket < 0) {
    stop("Failed to get connection socket");
  }

  do {
    // wait for any traffic on the db connection socket but no longer then 1s
    timeval timeout = {0, 0};
    timeout.tv_sec = 1;
    FD_SET(socket, &input);

    const int nfds = socket + 1;
    ret = select(nfds, &input, NULL, NULL, &timeout);
    if (ret == 0) {
      // timeout reached - check user interrupt
      checkUserInterrupt();
    } else if(ret < 0) {
      stop("select() failed with error code %d", SOCKERR);
    }
    // update db connection state using data available on the socket
    if (!PQconsumeInput(pConn_)) {
      stop("Failed to consume input from the server");
    }
  } while (PQisBusy(pConn_)); // check if PQgetResult will still block
}
