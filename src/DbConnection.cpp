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
  check_interrupts_(check_interrupts)
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
    stop(err);
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
      warning("Closing open result set, cancelling previous query");
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
  check_connection();

  // first allocate a 'cancel command' data structure.
  // should only return NULL if either:
  //  * the connection is NULL or
  //  * the connection is invalid.
  PGcancel* cancel = PQgetCancel(pConn_);
  if (cancel == NULL) stop("Connection error detected via PQgetCancel()");

  // PQcancel() actually issues the cancel command to the backend.
  char errbuf[256];
  if (!PQcancel(cancel, errbuf, sizeof(errbuf))) {
    warning(errbuf);
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

void DbConnection::copy_data(std::string sql, List df) {
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
}

void DbConnection::check_connection() {
  if (!pConn_) {
    stop("Disconnected");
  }

  ConnStatusType status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  // Status was bad, so try resetting.
  PQreset(pConn_);
  status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  conn_stop("Lost connection to database");
}

List DbConnection::info() {
  check_connection();

  const char* dbnm = PQdb(pConn_);
  const char* host = PQhost(pConn_);
  const char* port = PQport(pConn_);
  const char* user = PQuser(pConn_);
  int pver = PQprotocolVersion(pConn_);
  int sver = PQserverVersion(pConn_);
  int pid = PQbackendPID(pConn_);
  return
    List::create(
      _["dbname"] = dbnm == NULL ? "" : std::string(dbnm),
      _["host"]   = host == NULL ? "" : std::string(host),
      _["port"]   = port == NULL ? "" : std::string(port),
      _["username"] = user == NULL ? "" : std::string(user),
      _["protocol.version"]   = pver,
      _["server.version"]     = sver,
      _["db.version"]         = sver,
      _["pid"]                = pid
    );
}

bool DbConnection::is_check_interrupts() const {
  return check_interrupts_;
}

SEXP DbConnection::quote_string(const String& x) {
  // Returns a single CHRSXP
  check_connection();

  if (x == NA_STRING)
    return get_null_string();

  char* pq_escaped = PQescapeLiteral(pConn_, x.get_cstring(), static_cast<size_t>(-1));
  SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}

SEXP DbConnection::quote_identifier(const String& x) {
  // Returns a single CHRSXP
  check_connection();

  char* pq_escaped = PQescapeIdentifier(pConn_, x.get_cstring(), static_cast<size_t>(-1));
  SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}

SEXP DbConnection::get_null_string() {
  static RObject null = Rf_mkCharCE("NULL::text", CE_UTF8);
  return null;
}

bool DbConnection::is_transacting() const {
  return transacting_;
}

void DbConnection::set_transacting(bool transacting) {
  transacting_ = transacting;
}

void DbConnection::conn_stop(const char* msg) {
  conn_stop(conn(), msg);
}

void DbConnection::conn_stop(PGconn* conn, const char* msg) {
  stop("%s: %s", msg, PQerrorMessage(conn));
}

void DbConnection::cleanup_query() {
  if (pCurrentResult_ != NULL && !(pCurrentResult_->complete())) {
    cancel_query();
  }
  finish_query(pConn_);
}

List DbConnection::wait_for_notify(int timeout_secs) {
  PGnotify   *notify;
  List out;
  int socket = -1;
  fd_set input;

  while (TRUE) {
    // See if there's a notification waiting, if so return it
    if (!PQconsumeInput(pConn_)) {
      stop("Failed to consume input from the server");
    }
    if ((notify = PQnotifies(pConn_)) != NULL) {
      out = Rcpp::List::create(
        _["channel"] = CharacterVector::create(notify->relname),
        _["pid"] = IntegerVector::create(notify->be_pid),
        _["payload"] = CharacterVector::create(notify->extra)
      );
      PQfreemem(notify);
      return out;
    }

    if (socket != -1) {
      // Socket open, so already been round once, give up.
      return R_NilValue;
    }

    // Open DB socket and wait for new data for at most (timeout_secs) seconds
    if ((socket = PQsocket(pConn_)) < 0) {
      stop("Failed to get connection socket");
    }
    FD_ZERO(&input);
    FD_SET(socket, &input);
    timeval timeout = {0, 0};
    timeout.tv_sec = timeout_secs;
    if (select(socket + 1, &input, NULL, NULL, &timeout) < 0) {
        stop("select() on the connection failed");
    }
  }
}

void DbConnection::process_notice(void* /*This*/, const char* message) {
  Rcpp::CharacterVector msg(message);
  Rcpp::message(msg);
}
