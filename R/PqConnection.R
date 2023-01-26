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
#' rp <- r_bg(function() {
#'   library(DBI)
#'   Sys.sleep(0.3)
#'   db_notify <- dbConnect(RPostgres::Postgres())
#'   dbExecute(db_notify, "NOTIFY grapevine, 'psst'")
#'   dbDisconnect(db_notify)
#' })
#'
#' # Sleep until we get the message
#' n <- NULL
#' while (is.null(n)) {
#'   n <- RPostgres::postgresWaitForNotify(db_listen, 60)
#' }
#' stopifnot(n$payload == 'psst')
#'
#' # Tidy up
#' rp$wait()
#' dbDisconnect(db_listen)
postgresWaitForNotify <- function(conn, timeout = 1) {
  connection_wait_for_notify(conn@ptr, timeout)
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
  connection_is_transacting(conn@ptr)
}
