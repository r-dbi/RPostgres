#' @include PqDriver.R
NULL

#' PqConnection and methods.
#'
#' @keywords internal
#' @export
setClass("PqConnection",
  contains = "DBIConnection",
  slots = list(
    ptr = "externalptr",
    bigint = "character",
    timezone = "character",
    timezone_out = "character",
    typnames = "data.frame"
  )
)

# format()
#' @export
#' @rdname PqConnection-class
format.PqConnection <- function(x, ...) {
  if (dbIsValid(x)) {
    info <- dbGetInfo(x)

    if (info$host == "") {
      host <- "socket"
    } else {
      host <- paste0(info$host, ":", info$port)
    }

    details <- paste0(info$dbname, "@", host)
  } else {
    details <- "DISCONNECTED"
  }

  paste0("<PqConnection> ", details)
}

# show()
#' @export
#' @rdname PqConnection-class
setMethod("show", "PqConnection", function(object) {
  info <- dbGetInfo(object)

  if (info$host == "") {
    host <- "socket"
  } else {
    host <- paste0(info$host, ":", info$port)
  }

  cat("<PqConnection> ", info$dbname, "@", host, "\n", sep = "")
})

# dbIsValid()
#' @export
#' @rdname PqConnection-class
setMethod("dbIsValid", "PqConnection", function(dbObj, ...) {
  connection_valid(dbObj@ptr)
})

# dbSendQuery()

# dbSendStatement()

# dbDataType()
#' @export
#' @rdname dbDataType
setMethod("dbDataType", "PqConnection", function(dbObj, obj, ...) {
  if (is.data.frame(obj)) return(vapply(obj, dbDataType, "", dbObj = dbObj))
  get_data_type(obj)
})

get_data_type <- function(obj) {
  if (is.factor(obj)) return("TEXT")
  if (inherits(obj, "POSIXt")) return("TIMESTAMPTZ")
  if (inherits(obj, "Date")) return("DATE")
  if (inherits(obj, "difftime")) return("TIME")
  if (inherits(obj, "integer64")) return("BIGINT")
  switch(typeof(obj),
    integer = "INTEGER",
    double = "DOUBLE PRECISION",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "BYTEA",
    stop("Unsupported type", call. = FALSE)
  )
}

# dbQuoteString()

# dbQuoteIdentifier()

# dbWriteTable()

# dbReadTable()

# dbListTables()

# dbExistsTable()

# dbListFields()

# dbRemoveTable()

# dbGetInfo()
#' @export
#' @rdname PqConnection-class
setMethod("dbGetInfo", "PqConnection", function(dbObj, ...) {
  connection_info(dbObj@ptr)
})

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
#' @export
#' @rdname Postgres
#' @examplesIf postgresHasDefault()
#' library(DBI)
#' # Pass more arguments as necessary to dbConnect()
#' con <- dbConnect(RPostgres::Postgres())
#' dbDisconnect(con)
setMethod("dbConnect", "PqDriver",
  function(drv, dbname = NULL,
           host = NULL, port = NULL, password = NULL, user = NULL, service = NULL, ...,
           bigint = c("integer64", "integer", "numeric", "character"),
           check_interrupts = FALSE, timezone = "UTC", timezone_out = NULL) {

    opts <- unlist(list(dbname = dbname, user = user, password = password,
      host = host, port = as.character(port), service = service, client_encoding = "utf8", ...))
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
    conn
  })

check_tz <- function(timezone) {
  arg_name <- deparse(substitute(timezone))

  tryCatch(
    {
      # Side effect: check if time zone is valid
      lubridate::force_tz(as.POSIXct("2021-03-01 10:40"), timezone)
      timezone
    },
    error = function(e) {
      warning(
        "Invalid time zone '", timezone, "', ",
        "falling back to local time.\n",
        "Set the `", arg_name, "` argument to a valid time zone.\n",
        conditionMessage(e),
        call. = FALSE
      )
      ""
    }
  )
}

# dbDisconnect() (after dbConnect() to maintain order in documentation)
#' @export
#' @rdname Postgres
setMethod("dbDisconnect", "PqConnection", function(conn, ...) {
  connection_release(conn@ptr)
  invisible(TRUE)
})

#' Wait for and return any notifications that return within timeout
#'
#' Once you subscribe to notifications with LISTEN, use this to wait for
#' responses on each channel.
#'
#' @export
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @param timeout How long to wait, in seconds. Default 1
#' @return If a notification was available, a list of:
#' \describe{
#'   \item{channel}{Name of channel}
#'   \item{pid}{PID of notifying server process}
#'   \item{payload}{Content of notification}
#' }
#' If no notifications are available, return NULL
#' @examplesIf postgresHasDefault()
#' library(DBI)
#' library(callr)
#'
#' # listen for messages on the grapevine
#' db_listen <- dbConnect(RPostgres::Postgres())
#' dbExecute(db_listen, "LISTEN grapevine")
#'
#' # Start another process, which sends a message after a delay
#' rp <- r_bg(function () {
#'     library(DBI)
#'     Sys.sleep(0.3)
#'     db_notify <- dbConnect(RPostgres::Postgres())
#'     dbExecute(db_notify, "NOTIFY grapevine, 'psst'")
#'     dbDisconnect(db_notify)
#' })
#'
#' # Sleep until we get the message
#' n <- NULL
#' while (is.null(n)) {
#'     n <- RPostgres::postgresWaitForNotify(db_listen, 60)
#' }
#' stopifnot(n$payload == 'psst')
#'
#' # Tidy up
#' rp$wait()
#' dbDisconnect(db_listen)
postgresWaitForNotify <- function (conn, timeout = 1) {
  out <- connection_wait_for_notify(conn@ptr, timeout)
  if ('pid' %in% names(out)) out else NULL
}

#' Return whether a transaction is ongoing
#'
#' Detect whether the transaction is active for the given connection. A
#' transaction might be started with [dbBegin()] or wrapped within
#' [DBI::dbWithTransaction()].
#' @export
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @return A boolean, indicating if a transaction is ongoing.
postgresIsTransacting <- function(conn) {
  connection_is_transacting(conn)
}

#' Determine database type for R vector.
#'
#' @export
#' @param dbObj Postgres driver or connection.
#' @param obj Object to convert
#' @keywords internal
#' @rdname dbDataType
setMethod("dbDataType", "PqDriver", function(dbObj, obj, ...) {
  if (is.data.frame(obj)) return(vapply(obj, dbDataType, "", dbObj = dbObj))
  get_data_type(obj)
})
