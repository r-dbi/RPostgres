# dbBegin()
# dbCommit()
# dbRollback()
# other
#' Connect to a PostgreSQL database
#'
#' @description
#' `DBI::dbConnect()` establishes a connection to a database.
#' Set `drv = RPostgres::Postgres()` to connect to a SQL database
#' using the \pkg{RPostgres} package.
#'
#' Manually disconnecting a connection is not necessary with \pkg{RPostgres},
#' but still recommended;
#' if you delete the object containing the connection, it will be automatically
#' disconnected during the next GC with a warning.
#'
#' @param drv Should be set to [RPostgres::Postgres()]
#'   to use the \pkg{RPostgres} package.
#' @param dbname Database name. If `NULL`, defaults to the user name.
#'   Note that this argument can only contain the database name, it will not
#'   be parsed as a connection string (internally, `expand_dbname` is set to
#'   `false` in the call to
#'   [`PQconnectdbParams()`](https://www.postgresql.org/docs/current/libpq-connect.html)).
#' @param user,password User name and password. If `NULL`, will be
#'   retrieved from `PGUSER` and `PGPASSWORD` envvars, or from the
#'   appropriate line in `~/.pgpass`. See
#'   <https://www.postgresql.org/docs/current/libpq-pgpass.html> for
#'   more details.
#' @param host,port Host and port. If `NULL`, will be retrieved from
#'   `PGHOST` and `PGPORT` env vars.
#' @param service Name of service to connect as.  If `NULL`, will be
#'   ignored.  Otherwise, connection parameters will be loaded from the pg_service.conf
#'   file and used.  See <https://www.postgresql.org/docs/current/libpq-pgservice.html>
#'   for details on this file and syntax.
#' @param ... Other name-value pairs that describe additional connection
#'   options as described at
#'   <https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS>
#' @param bigint The R type that 64-bit integer types should be mapped to,
#'   default is [bit64::integer64], which allows the full range of 64 bit
#'   integers.
#' @param check_interrupts Should user interrupts be checked during the query execution (before
#'   first row of data is available)? Setting to `TRUE` allows interruption of queries
#'   running too long.
#' @param timezone Sets the timezone for the connection. The default is `"UTC"`.
#'   If `NULL` then no timezone is set, which defaults to the server's time zone.
#' @param timezone_out The time zone returned to R, defaults to `timezone`.
#'   If you want to display datetime values in the local timezone,
#'   set to [Sys.timezone()] or `""`.
#'   This setting does not change the time values returned, only their display.
#' @param conn Connection to disconnect.
#' @rdname Postgres
#' @examplesIf postgresHasDefault()
#' library(DBI)
#' # Pass more arguments as necessary to dbConnect()
#' con <- dbConnect(RPostgres::Postgres())
#' dbDisconnect(con)
#' @usage NULL
dbConnect_PqDriver <- function(drv, dbname = NULL,
                               host = NULL, port = NULL, password = NULL, user = NULL, service = NULL, ...,
                               bigint = c("integer64", "integer", "numeric", "character"),
                               check_interrupts = FALSE, timezone = "UTC", timezone_out = NULL) {
  opts <- unlist(list(
    dbname = dbname, user = user, password = password,
    host = host, port = as.character(port), service = service, client_encoding = "utf8", ...
  ))
  if (!is.character(opts)) {
    stop("All options should be strings", call. = FALSE)
  }
  bigint <- match.arg(bigint)
  stopifnot(is.logical(check_interrupts), all(!is.na(check_interrupts)), length(check_interrupts) == 1)
  if (!is.null(timezone)) {
    stopifnot(is.character(timezone), all(!is.na(timezone)), length(timezone) == 1)
  }
  if (!is.null(timezone_out)) {
    stopifnot(is.character(timezone_out), all(!is.na(timezone_out)), length(timezone_out) == 1)
  }

  if (length(opts) == 0) {
    ptr <- connection_create(character(), character(), check_interrupts)
  } else {
    ptr <- connection_create(names(opts), as.vector(opts), check_interrupts)
  }

  # timezone is set later
  conn <- new("PqConnection",
    ptr = ptr, bigint = bigint, timezone = character(), typnames = data.frame()
  )
  on.exit(dbDisconnect(conn))

  # set datestyle workaround - https://github.com/r-dbi/RPostgres/issues/287
  dbExecute(conn, "SET datestyle to 'iso, mdy'", immediate = TRUE)

  if (!is.null(timezone)) {
    # Side effect: check if time zone valid
    dbExecute(conn, paste0("SET TIMEZONE = ", dbQuoteString(conn, timezone)), immediate = TRUE)
  } else {
    timezone <- dbGetQuery(conn, "SHOW timezone", immediate = TRUE)[[1]]
  }

  # Check if this is a valid time zone in R:
  timezone <- check_tz(timezone)

  if (is.null(timezone_out)) {
    timezone_out <- timezone
  } else {
    timezone_out <- check_tz(timezone_out)
  }

  conn@timezone <- timezone
  conn@timezone_out <- timezone_out
  conn@typnames <- dbGetQuery(conn, "SELECT oid, typname FROM pg_type", immediate = TRUE)

  on.exit(NULL)

  # perform the connection notification at the top level, to ensure that it's had
  # a chance to get its external pointer connected, and so we can capture the
  # expression that created it
  if (!is.null(getOption("connectionObserver"))) { # nocov start
    addTaskCallback(function(expr, ...) {
      tryCatch({
        if (is.call(expr) &&
            as.character(expr[[1]]) %in% c("<-", "=") &&
            "dbConnect" %in% as.character(expr[[3]][[1]])) {

          # notify if this is an assignment we can replay
          on_connection_opened(eval(expr[[2]]), paste(
            c("library(DBI)", deparse(expr)), collapse = "\n"))
        }
      }, error = function(e) {
        warning("Could not notify connection observer. ", e$message, call. = FALSE)
      })

      # always return false so the task callback is run at most once
      FALSE
    })
  } # nocov end

  conn
}

#' @rdname Postgres
#' @export
setMethod("dbConnect", "PqDriver", dbConnect_PqDriver)
