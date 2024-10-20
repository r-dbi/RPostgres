#ifndef __RPOSTGRES_PQ_CONNECTION__
#define __RPOSTGRES_PQ_CONNECTION__

#include <boost/noncopyable.hpp>
#include <boost/shared_ptr.hpp>

class DbResult;

// convenience typedef for shared_ptr to DbConnection
class DbConnection;
typedef boost::shared_ptr<DbConnection> DbConnectionPtr;

// DbConnection ----------------------------------------------------------------

class DbConnection : boost::noncopyable {
  PGconn* pConn_;
  const DbResult* pCurrentResult_;
  bool transacting_;
  bool check_interrupts_;
  cpp11::strings temp_schema_;

public:
  DbConnection(std::vector<std::string> keys, std::vector<std::string> values,
    bool check_interrupts);
  virtual ~DbConnection();

public:
  void disconnect();

  PGconn* conn();

  void set_current_result(const DbResult* pResult);
  void reset_current_result(const DbResult* pResult);
  bool is_current_result(const DbResult* pResult);
  bool has_query();

  void copy_data(std::string sql, cpp11::list df);
  
  Oid import_lo_from_file(std::string file_path, Oid p_oid);
  

  void check_connection();
  cpp11::list info();

  bool is_check_interrupts() const;

  SEXP quote_string(const cpp11::r_string& x);
  SEXP quote_identifier(const cpp11::r_string& x);
  static SEXP get_null_string();

  bool is_transacting() const;
  void set_transacting(bool transacting);

  cpp11::strings get_temp_schema() const;
  void set_temp_schema(cpp11::strings temp_schema);

  void conn_stop(const char* msg);
  static void conn_stop(PGconn* conn, const char* msg);

  void cleanup_query();
  static void finish_query(PGconn* pConn);
  cpp11::list wait_for_notify(int timeout_secs);

  void cancel_query();

private:
  static void process_notice(void* This, const char* message);
};

#endif
