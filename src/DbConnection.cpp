#include "pch.h"
#include "DbConnection.h"
#include "encode.h"
#include "DbResult.h"

#ifdef _WIN32
#include <winsock2.h>
#endif

DbConnection::DbConnection(std::vector<std::string> keys, std::vector<std::string> values,
                           bool check_interrupts) :
  pCurrentResult_(NULL),
  transacting_(false),
  check_interrupts_(check_interrupts),
  temp_schema_(cpp11::as_sexp(cpp11::r_string(NA_STRING)))
{
  size_t n = keys.size();
  std::vector<const char*> c_keys(n + 1), c_values(n + 1);

  for (size_t i = 0; i < n; ++i) {
    c_keys[i] = keys[i].c_str();
    c_values[i] = values[i].c_str();
  }
  c_keys[n] = NULL;
  c_values[n] = NULL;

  pConn_ = PQconnectdbParams(&c_keys[0], &c_values[0], false);

  if (PQstatus(pConn_) != CONNECTION_OK) {
    std::string err = PQerrorMessage(pConn_);
    PQfinish(pConn_);
    cpp11::stop(err);
  }

  PQsetClientEncoding(pConn_, "UTF-8");

  PQsetNoticeProcessor(pConn_, &process_notice, this);
}

DbConnection::~DbConnection() {
  LOG_VERBOSE;
  disconnect();
}

void DbConnection::disconnect() {
  try {
    LOG_VERBOSE;
    PQfinish(pConn_);
    LOG_VERBOSE;
    pConn_ = NULL;
  } catch (...) {}
}

PGconn* DbConnection::conn() {
  return pConn_;
}

void DbConnection::set_current_result(const DbResult* pResult) {
  // same result pointer, nothing to do.
  if (pResult == pCurrentResult_)
    return;

  // try to clean up remnants of any previous queries.
  // (even if (the new) pResult is NULL, we should try to reset the back-end.)
  if (pCurrentResult_ != NULL) {
    if (pResult != NULL) {
      cpp11::warning(std::string("Closing open result set, cancelling previous query"));
    }

    cleanup_query();
  }

  pCurrentResult_ = pResult;
}


void DbConnection::reset_current_result(const DbResult* pResult) {
  // FIXME: inactive result pointer, what to do?
  if (pResult != pCurrentResult_)
    return;

  cleanup_query();
  pCurrentResult_ = NULL;
}


/**
 * Documentation for canceling queries:
 * https://www.postgresql.org/docs/current/libpq-cancel.html
 **/
void DbConnection::cancel_query() {
  LOG_DEBUG;

  check_connection();

  // first allocate a 'cancel command' data structure.
  // should only return NULL if either:
  //  * the connection is NULL or
  //  * the connection is invalid.
  PGcancel* cancel = PQgetCancel(pConn_);
  if (cancel == NULL) cpp11::stop(std::string("Connection error detected via PQgetCancel()"));

  LOG_DEBUG;

  // PQcancel() actually issues the cancel command to the backend.
  char errbuf[256];
  if (!PQcancel(cancel, errbuf, sizeof(errbuf))) {
    cpp11::warning(std::string(errbuf));
  }

  // free up the data structure allocated by PQgetCancel().
  PQfreeCancel(cancel);
}

void DbConnection::finish_query(PGconn* pConn) {
  // Clear pending results
  PGresult* result;
  while ((result = PQgetResult(pConn)) != NULL) {
    PQclear(result);
  }
}

bool DbConnection::is_current_result(const DbResult* pResult) {
  return pCurrentResult_ == pResult;
}

bool DbConnection::has_query() {
  return pCurrentResult_ != NULL;
}

Oid DbConnection::import_lo_from_file(std::string filename, Oid p_oid) {
  Oid lo_oid = lo_import_with_oid(pConn_, filename.c_str(), p_oid);
  if (lo_oid == InvalidOid) cpp11::stop(PQerrorMessage(pConn_));
  return(lo_oid);
}

void DbConnection::copy_data(std::string sql, cpp11::list df) {
  LOG_DEBUG << sql;

  R_xlen_t p = df.size();
  if (p == 0)
    return;

  PGresult* pInit = PQexec(pConn_, sql.c_str());
  if (PQresultStatus(pInit) != PGRES_COPY_IN) {
    PQclear(pInit);
    conn_stop("Failed to initialise COPY");
  }
  PQclear(pInit);


  std::string buffer;
  int n = Rf_length(df[0]);
  // Sending row at-a-time is faster, presumable because it avoids copies
  // of buffer. Sending data asynchronously appears to be no faster.
  for (int i = 0; i < n; ++i) {
    buffer.clear();
    encode_row_in_buffer(df, i, buffer);

    if (PQputCopyData(pConn_, buffer.data(), static_cast<int>(buffer.size())) != 1) {
      conn_stop("Failed to put data");
    }
  }


  if (PQputCopyEnd(pConn_, NULL) != 1) {
    conn_stop("Failed to finish COPY");
  }

  PGresult* pComplete = PQgetResult(pConn_);
  if (PQresultStatus(pComplete) != PGRES_COMMAND_OK) {
    PQclear(pComplete);
    conn_stop("COPY returned error");
  }
  PQclear(pComplete);

  finish_query(pConn_);
}

void DbConnection::check_connection() {
  if (!pConn_) {
    cpp11::stop(std::string("Disconnected"));
  }

  ConnStatusType status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  // Status was bad, so try resetting.
  PQreset(pConn_);
  status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  conn_stop("Lost connection to database");
}

cpp11::list DbConnection::info() {
  using namespace cpp11::literals;
  check_connection();

  const char* dbnm = PQdb(pConn_);
  const char* host = PQhost(pConn_);
  const char* port = PQport(pConn_);
  const char* user = PQuser(pConn_);
  int pver = PQprotocolVersion(pConn_);
  int sver = PQserverVersion(pConn_);
  int pid = PQbackendPID(pConn_);
  return
    cpp11::list({
      "dbname"_nm = dbnm == NULL ? "" : std::string(dbnm),
      "host"_nm   = host == NULL ? "" : std::string(host),
      "port"_nm   = port == NULL ? "" : std::string(port),
      "username"_nm = user == NULL ? "" : std::string(user),
      "protocol.version"_nm   = pver,
      "server.version"_nm     = sver,
      "db.version"_nm         = sver,
      "pid"_nm                = pid
    });
}

bool DbConnection::is_check_interrupts() const {
  return check_interrupts_;
}

SEXP DbConnection::quote_string(const cpp11::r_string& x) {
  // Returns a single CHRSXP
  check_connection();

  if (x == NA_STRING)
    return get_null_string();

  const auto str = static_cast<std::string>(x);
  char* pq_escaped = PQescapeLiteral(pConn_, str.c_str(), static_cast<size_t>(-1));
  auto escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}

SEXP DbConnection::quote_identifier(const cpp11::r_string& x) {
  // Returns a single CHRSXP
  check_connection();

  const auto str = static_cast<std::string>(x);
  char* pq_escaped = PQescapeIdentifier(pConn_, str.c_str(), static_cast<size_t>(-1));
  auto escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}

SEXP DbConnection::get_null_string() {
  static cpp11::sexp null = Rf_mkCharCE("NULL", CE_UTF8);
  return null;
}

bool DbConnection::is_transacting() const {
  return transacting_;
}

void DbConnection::set_transacting(bool transacting) {
  transacting_ = transacting;
}

cpp11::strings DbConnection::get_temp_schema() const {
  return temp_schema_;
}

void DbConnection::set_temp_schema(cpp11::strings temp_schema) {
  temp_schema_ = temp_schema;
}

void DbConnection::conn_stop(const char* msg) {
  conn_stop(conn(), msg);
}

void DbConnection::conn_stop(PGconn* conn, const char* msg) {
  cpp11::stop(std::string(msg) + " : " + PQerrorMessage(conn));
}

void DbConnection::cleanup_query() {
  if (!pConn_) {
    return;
  }

  if (pCurrentResult_ != NULL && !(pCurrentResult_->complete())) {
    cancel_query();
  }
  finish_query(pConn_);
}

cpp11::list DbConnection::wait_for_notify(int timeout_secs) {
  using namespace cpp11::literals;
  PGnotify   *notify;
  cpp11::writable::list out;
  int socket = -1;
  fd_set input;

  while (TRUE) {
    // See if there's a notification waiting, if so return it
    if (!PQconsumeInput(pConn_)) {
      cpp11::stop("Failed to consume input from the server");
    }
    if ((notify = PQnotifies(pConn_)) != NULL) {
      out = cpp11::list({
        "channel"_nm = cpp11::writable::strings({notify->relname}),
        "pid"_nm = cpp11::writable::integers({notify->be_pid}),
        "payload"_nm = cpp11::writable::strings({notify->extra})
      });
      PQfreemem(notify);
      return out;
    }

    if (socket != -1) {
      // Socket open, so already been round once, give up.
      return cpp11::list();
    }

    // Open DB socket and wait for new data for at most (timeout_secs) seconds
    if ((socket = PQsocket(pConn_)) < 0) {
      cpp11::stop("Failed to get connection socket");
    }
    FD_ZERO(&input);
    FD_SET(socket, &input);
    timeval timeout = {0, 0};
    timeout.tv_sec = timeout_secs;
    if (select(socket + 1, &input, NULL, NULL, &timeout) < 0) {
        cpp11::stop("select() on the connection failed");
    }
  }
}

void DbConnection::process_notice(void* /*This*/, const char* message) {
  cpp11::message(message);
}
