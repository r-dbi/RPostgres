#' Check if default database is available.
#'
#' RPostgres examples and tests connect to a default database via
#' `dbConnect(`[RPostgres::Postgres()]`)`. This function checks if that
#' database is available, and if not, displays an informative message.
#'
#' @param ... Additional arguments passed on to [dbConnect()]
#' @export
#' @examples
#' if (postgresHasDefault()) {
#'   db <- postgresDefault()
#'   print(dbListTables(db))
#'   dbDisconnect(db)
#' } else {
#'   message("No database connection.")
#' }
postgresHasDefault <- function(...) {
  tryCatch(
    {
      con <- connect_default(...)
      dbDisconnect(con)
      TRUE
    },
    error = function(...) {
      message(
        "Could not initialise default postgres database. If postgres is running\n",
        "check that the connection works with default libpq settings.\n",
        "The default connection uses the PGHOST, PGPORT, PGUSER, PGPASSWORD,\n",
        "and PGDATABASE environment variables. If unset, libpq defaults are\n",
        "used (local socket, port 5432, OS user name).\n",
        "See https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS"
      )
      FALSE
    }
  )
}

#' @description
#' `postgresDefault()` works similarly but returns a connection on success and
#' throws a testthat skip condition on failure, making it suitable for use in
#' tests.
#' @export
#' @rdname postgresHasDefault
postgresDefault <- function(...) {
  tryCatch(
    {
      connect_default(...)
    },
    error = function(...) {
      testthat::skip("Test database not available")
    }
  )
}

connect_default <- function(...) {
  dbConnect(Postgres(), ...)
}
