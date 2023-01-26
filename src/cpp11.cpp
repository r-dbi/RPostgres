// Generated by cpp11: do not edit by hand
// clang-format off

#include "RPostgres_types.h"
#include <cpp11/R.hpp>
#include <Rcpp.h>
using namespace Rcpp;
#include "cpp11/declarations.hpp"
#include <R_ext/Visibility.h>

// connection.cpp
int client_version();
extern "C" SEXP _RPostgres_client_version() {
  BEGIN_CPP11
    return cpp11::as_sexp(client_version());
  END_CPP11
}
// connection.cpp
cpp11::external_pointer<DbConnectionPtr> connection_create(std::vector<std::string> keys, std::vector<std::string> values, bool check_interrupts);
extern "C" SEXP _RPostgres_connection_create(SEXP keys, SEXP values, SEXP check_interrupts) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_create(cpp11::as_cpp<cpp11::decay_t<std::vector<std::string>>>(keys), cpp11::as_cpp<cpp11::decay_t<std::vector<std::string>>>(values), cpp11::as_cpp<cpp11::decay_t<bool>>(check_interrupts)));
  END_CPP11
}
// connection.cpp
bool connection_valid(cpp11::external_pointer<DbConnectionPtr> con_);
extern "C" SEXP _RPostgres_connection_valid(SEXP con_) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_valid(cpp11::as_cpp<cpp11::decay_t<cpp11::external_pointer<DbConnectionPtr>>>(con_)));
  END_CPP11
}
// connection.cpp
void connection_release(cpp11::external_pointer<DbConnectionPtr> con_);
extern "C" SEXP _RPostgres_connection_release(SEXP con_) {
  BEGIN_CPP11
    connection_release(cpp11::as_cpp<cpp11::decay_t<cpp11::external_pointer<DbConnectionPtr>>>(con_));
    return R_NilValue;
  END_CPP11
}
// connection.cpp
cpp11::list connection_info(DbConnection* con);
extern "C" SEXP _RPostgres_connection_info(SEXP con) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_info(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con)));
  END_CPP11
}
// connection.cpp
cpp11::strings connection_quote_string(DbConnection* con, cpp11::strings xs);
extern "C" SEXP _RPostgres_connection_quote_string(SEXP con, SEXP xs) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_quote_string(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<cpp11::strings>>(xs)));
  END_CPP11
}
// connection.cpp
cpp11::strings connection_quote_identifier(DbConnection* con, cpp11::strings xs);
extern "C" SEXP _RPostgres_connection_quote_identifier(SEXP con, SEXP xs) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_quote_identifier(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<cpp11::strings>>(xs)));
  END_CPP11
}
// connection.cpp
bool connection_is_transacting(DbConnection* con);
extern "C" SEXP _RPostgres_connection_is_transacting(SEXP con) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_is_transacting(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con)));
  END_CPP11
}
// connection.cpp
void connection_set_transacting(DbConnection* con, bool transacting);
extern "C" SEXP _RPostgres_connection_set_transacting(SEXP con, SEXP transacting) {
  BEGIN_CPP11
    connection_set_transacting(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<bool>>(transacting));
    return R_NilValue;
  END_CPP11
}
// connection.cpp
void connection_copy_data(DbConnection* con, std::string sql, cpp11::list df);
extern "C" SEXP _RPostgres_connection_copy_data(SEXP con, SEXP sql, SEXP df) {
  BEGIN_CPP11
    connection_copy_data(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<std::string>>(sql), cpp11::as_cpp<cpp11::decay_t<cpp11::list>>(df));
    return R_NilValue;
  END_CPP11
}
// connection.cpp
cpp11::list connection_wait_for_notify(DbConnection* con, int timeout_secs);
extern "C" SEXP _RPostgres_connection_wait_for_notify(SEXP con, SEXP timeout_secs) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_wait_for_notify(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<int>>(timeout_secs)));
  END_CPP11
}
// connection.cpp
cpp11::strings connection_get_temp_schema(DbConnection* con);
extern "C" SEXP _RPostgres_connection_get_temp_schema(SEXP con) {
  BEGIN_CPP11
    return cpp11::as_sexp(connection_get_temp_schema(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con)));
  END_CPP11
}
// connection.cpp
void connection_set_temp_schema(DbConnection* con, cpp11::strings temp_schema);
extern "C" SEXP _RPostgres_connection_set_temp_schema(SEXP con, SEXP temp_schema) {
  BEGIN_CPP11
    connection_set_temp_schema(cpp11::as_cpp<cpp11::decay_t<DbConnection*>>(con), cpp11::as_cpp<cpp11::decay_t<cpp11::strings>>(temp_schema));
    return R_NilValue;
  END_CPP11
}
// encode.cpp
std::string encode_vector(cpp11::sexp x);
extern "C" SEXP _RPostgres_encode_vector(SEXP x) {
  BEGIN_CPP11
    return cpp11::as_sexp(encode_vector(cpp11::as_cpp<cpp11::decay_t<cpp11::sexp>>(x)));
  END_CPP11
}
// encode.cpp
std::string encode_data_frame(cpp11::list x);
extern "C" SEXP _RPostgres_encode_data_frame(SEXP x) {
  BEGIN_CPP11
    return cpp11::as_sexp(encode_data_frame(cpp11::as_cpp<cpp11::decay_t<cpp11::list>>(x)));
  END_CPP11
}
// encrypt.cpp
cpp11::r_string encrypt_password(cpp11::r_string password, cpp11::r_string user);
extern "C" SEXP _RPostgres_encrypt_password(SEXP password, SEXP user) {
  BEGIN_CPP11
    return cpp11::as_sexp(encrypt_password(cpp11::as_cpp<cpp11::decay_t<cpp11::r_string>>(password), cpp11::as_cpp<cpp11::decay_t<cpp11::r_string>>(user)));
  END_CPP11
}
// logging.cpp
void init_logging(const std::string& log_level);
extern "C" SEXP _RPostgres_init_logging(SEXP log_level) {
  BEGIN_CPP11
    init_logging(cpp11::as_cpp<cpp11::decay_t<const std::string&>>(log_level));
    return R_NilValue;
  END_CPP11
}
// result.cpp
cpp11::external_pointer<DbResult> result_create(cpp11::external_pointer<DbConnectionPtr> con, std::string sql, bool immediate);
extern "C" SEXP _RPostgres_result_create(SEXP con, SEXP sql, SEXP immediate) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_create(cpp11::as_cpp<cpp11::decay_t<cpp11::external_pointer<DbConnectionPtr>>>(con), cpp11::as_cpp<cpp11::decay_t<std::string>>(sql), cpp11::as_cpp<cpp11::decay_t<bool>>(immediate)));
  END_CPP11
}
// result.cpp
void result_release(cpp11::external_pointer<DbResult> res);
extern "C" SEXP _RPostgres_result_release(SEXP res) {
  BEGIN_CPP11
    result_release(cpp11::as_cpp<cpp11::decay_t<cpp11::external_pointer<DbResult>>>(res));
    return R_NilValue;
  END_CPP11
}
// result.cpp
bool result_valid(cpp11::external_pointer<DbResult> res_);
extern "C" SEXP _RPostgres_result_valid(SEXP res_) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_valid(cpp11::as_cpp<cpp11::decay_t<cpp11::external_pointer<DbResult>>>(res_)));
  END_CPP11
}
// result.cpp
List result_fetch(DbResult* res, const int n);
extern "C" SEXP _RPostgres_result_fetch(SEXP res, SEXP n) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_fetch(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res), cpp11::as_cpp<cpp11::decay_t<const int>>(n)));
  END_CPP11
}
// result.cpp
void result_bind(DbResult* res, List params);
extern "C" SEXP _RPostgres_result_bind(SEXP res, SEXP params) {
  BEGIN_CPP11
    result_bind(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res), cpp11::as_cpp<cpp11::decay_t<List>>(params));
    return R_NilValue;
  END_CPP11
}
// result.cpp
bool result_has_completed(DbResult* res);
extern "C" SEXP _RPostgres_result_has_completed(SEXP res) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_has_completed(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res)));
  END_CPP11
}
// result.cpp
int result_rows_fetched(DbResult* res);
extern "C" SEXP _RPostgres_result_rows_fetched(SEXP res) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_rows_fetched(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res)));
  END_CPP11
}
// result.cpp
int result_rows_affected(DbResult* res);
extern "C" SEXP _RPostgres_result_rows_affected(SEXP res) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_rows_affected(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res)));
  END_CPP11
}
// result.cpp
List result_column_info(DbResult* res);
extern "C" SEXP _RPostgres_result_column_info(SEXP res) {
  BEGIN_CPP11
    return cpp11::as_sexp(result_column_info(cpp11::as_cpp<cpp11::decay_t<DbResult*>>(res)));
  END_CPP11
}

extern "C" {
static const R_CallMethodDef CallEntries[] = {
    {"_RPostgres_client_version",              (DL_FUNC) &_RPostgres_client_version,              0},
    {"_RPostgres_connection_copy_data",        (DL_FUNC) &_RPostgres_connection_copy_data,        3},
    {"_RPostgres_connection_create",           (DL_FUNC) &_RPostgres_connection_create,           3},
    {"_RPostgres_connection_get_temp_schema",  (DL_FUNC) &_RPostgres_connection_get_temp_schema,  1},
    {"_RPostgres_connection_info",             (DL_FUNC) &_RPostgres_connection_info,             1},
    {"_RPostgres_connection_is_transacting",   (DL_FUNC) &_RPostgres_connection_is_transacting,   1},
    {"_RPostgres_connection_quote_identifier", (DL_FUNC) &_RPostgres_connection_quote_identifier, 2},
    {"_RPostgres_connection_quote_string",     (DL_FUNC) &_RPostgres_connection_quote_string,     2},
    {"_RPostgres_connection_release",          (DL_FUNC) &_RPostgres_connection_release,          1},
    {"_RPostgres_connection_set_temp_schema",  (DL_FUNC) &_RPostgres_connection_set_temp_schema,  2},
    {"_RPostgres_connection_set_transacting",  (DL_FUNC) &_RPostgres_connection_set_transacting,  2},
    {"_RPostgres_connection_valid",            (DL_FUNC) &_RPostgres_connection_valid,            1},
    {"_RPostgres_connection_wait_for_notify",  (DL_FUNC) &_RPostgres_connection_wait_for_notify,  2},
    {"_RPostgres_encode_data_frame",           (DL_FUNC) &_RPostgres_encode_data_frame,           1},
    {"_RPostgres_encode_vector",               (DL_FUNC) &_RPostgres_encode_vector,               1},
    {"_RPostgres_encrypt_password",            (DL_FUNC) &_RPostgres_encrypt_password,            2},
    {"_RPostgres_init_logging",                (DL_FUNC) &_RPostgres_init_logging,                1},
    {"_RPostgres_result_bind",                 (DL_FUNC) &_RPostgres_result_bind,                 2},
    {"_RPostgres_result_column_info",          (DL_FUNC) &_RPostgres_result_column_info,          1},
    {"_RPostgres_result_create",               (DL_FUNC) &_RPostgres_result_create,               3},
    {"_RPostgres_result_fetch",                (DL_FUNC) &_RPostgres_result_fetch,                2},
    {"_RPostgres_result_has_completed",        (DL_FUNC) &_RPostgres_result_has_completed,        1},
    {"_RPostgres_result_release",              (DL_FUNC) &_RPostgres_result_release,              1},
    {"_RPostgres_result_rows_affected",        (DL_FUNC) &_RPostgres_result_rows_affected,        1},
    {"_RPostgres_result_rows_fetched",         (DL_FUNC) &_RPostgres_result_rows_fetched,         1},
    {"_RPostgres_result_valid",                (DL_FUNC) &_RPostgres_result_valid,                1},
    {NULL, NULL, 0}
};
}

extern "C" attribute_visible void R_init_RPostgres(DllInfo* dll){
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}