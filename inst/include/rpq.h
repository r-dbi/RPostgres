#include <Rcpp.h>
#include <libpq-fe.h>

class PqConnection {
  PGconn* conn;

public:
  PqConnection(std::vector<std::string> keys_, std::vector<std::string> values_) {
    int n = keys_.size();
    std::vector<const char*> keys(n + 1), values(n + 1);

    for (int i = 0; i < n; ++i) {
      keys[i] = keys_[i].c_str();
      values[i] = values_[i].c_str();
    }
    keys[n] = NULL;
    values[n] = NULL;

    conn = PQconnectdbParams(&keys[0], &values[0], false);

    if (PQstatus(conn) != CONNECTION_OK) {
      std::string err = PQerrorMessage(conn);
      PQfinish(conn);
      Rcpp::stop(err);
    }
  }

  ~PqConnection() {
    if (conn != NULL) {
      PQfinish(conn);
    }
  };

};
