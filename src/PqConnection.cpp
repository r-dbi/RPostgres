#include "pch.h"
#include "PqConnection.h"
#include "encode.h"
#include <cstdlib>


PqConnection::PqConnection(std::vector<std::string> keys, std::vector<std::string> values) :
  pCurrentResult_(NULL) {
  size_t n = keys.size();
  std::vector<const char*> c_keys(n + 1), c_values(n + 1);

  for (size_t i = 0; i < n; ++i) {
    c_keys[i] = keys[i].c_str();
    c_values[i] = values[i].c_str();
  }
  c_keys[n] = NULL;
  c_values[n] = NULL;
  setenv("PGTZ", "UTC", 1);
  pConn_ = PQconnectdbParams(&c_keys[0], &c_values[0], false);

  if (PQstatus(pConn_) != CONNECTION_OK) {
    std::string err = PQerrorMessage(pConn_);
    PQfinish(pConn_);
    Rcpp::stop(err);
  }

  PQsetClientEncoding(pConn_, "UTF-8");
}

PqConnection::~PqConnection() {
  try {
    PQfinish(pConn_);
  } catch (...) {}
}

PGconn* PqConnection::conn() {
  return pConn_;
}

void PqConnection::setCurrentResult(PqResult* pResult) {
  // Cancels previous query, if needed.
  if (pResult == pCurrentResult_)
    return;

  if (pCurrentResult_ != NULL) {
    if (pResult != NULL)
      Rcpp::warning("Cancelling previous query");

    cancelQuery();
  }
  pCurrentResult_ = pResult;
}

void PqConnection::cancelQuery() {
  conCheck();

  // Cancel running query
  PGcancel* cancel = PQgetCancel(pConn_);
  if (cancel == NULL) {
    Rcpp::warning("Failed to cancel running query");
    return;
  }

  char errbuf[256];
  if (!PQcancel(cancel, errbuf, 256)) {
    Rcpp::warning(errbuf);
  }

  PQfreeCancel(cancel);

  // Clear pending results
  PGresult* result;
  while ((result = PQgetResult(pConn_)) != NULL) {
    PQclear(result);
  }
}

bool PqConnection::isCurrentResult(PqResult* pResult) {
  return pCurrentResult_ == pResult;
}

bool PqConnection::hasQuery() {
  return pCurrentResult_ != NULL;
}

void PqConnection::copyData(std::string sql, Rcpp::List df) {
  R_xlen_t p = df.size();
  if (p == 0)
    return;

  PGresult* pInit = PQexec(pConn_, sql.c_str());
  if (PQresultStatus(pInit) != PGRES_COPY_IN) {
    PQclear(pInit);
    Rcpp::stop("Failed to initialise COPY");
  }
  PQclear(pInit);


  std::string buffer;
  int n = Rf_length(df[0]);
  // Sending row at-a-time is faster, presumable because it avoids copies
  // of buffer. Sending data asynchronously appears to be no faster.
  for (int i = 0; i < n; ++i) {
    buffer.clear();
    encodeRowInBuffer(df, i, buffer);

    if (PQputCopyData(pConn_, buffer.data(), static_cast<int>(buffer.size())) != 1) {
      Rcpp::stop(PQerrorMessage(pConn_));
    }
  }


  if (PQputCopyEnd(pConn_, NULL) != 1) {
    Rcpp::stop(PQerrorMessage(pConn_));
  }

  PGresult* pComplete = PQgetResult(pConn_);
  if (PQresultStatus(pComplete) != PGRES_COMMAND_OK) {
    PQclear(pComplete);
    Rcpp::stop(PQerrorMessage(pConn_));
  }
  PQclear(pComplete);
}

void PqConnection::conCheck() {
  ConnStatusType status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  // Status was bad, so try resetting.
  PQreset(pConn_);
  status = PQstatus(pConn_);
  if (status == CONNECTION_OK) return;

  Rcpp::stop("Lost connection to database");
}

Rcpp::List PqConnection::info() {
  conCheck();

  const char* dbnm = PQdb(pConn_);
  const char* host = PQhost(pConn_);
  const char* port = PQport(pConn_);
  const char* user = PQuser(pConn_);
  int pver = PQprotocolVersion(pConn_);
  int sver = PQserverVersion(pConn_);
  int pid = PQbackendPID(pConn_);
  return
    Rcpp::List::create(
      Rcpp::_["dbname"] = dbnm == NULL ? "" : std::string(dbnm),
      Rcpp::_["host"]   = host == NULL ? "" : std::string(host),
      Rcpp::_["port"]   = port == NULL ? "" : std::string(port),
      Rcpp::_["user"]   = user == NULL ? "" : std::string(user),
      Rcpp::_["protocol_version"]   = pver,
      Rcpp::_["server_version"]     = sver,
      Rcpp::_["pid"]                = pid
    );
}

SEXP PqConnection::escapeString(std::string x) {
  // Returns a single CHRSXP
  conCheck();

  char* pq_escaped = PQescapeLiteral(pConn_, x.c_str(), x.length());
  SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}

SEXP PqConnection::escapeIdentifier(std::string x) {
  // Returns a single CHRSXP
  conCheck();

  char* pq_escaped = PQescapeIdentifier(pConn_, x.c_str(), x.length());
  SEXP escaped = Rf_mkCharCE(pq_escaped, CE_UTF8);
  PQfreemem(pq_escaped);

  return escaped;
}
