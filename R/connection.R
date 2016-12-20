#' @include driver.R
NULL

#' PqConnection and methods.
#'
#' @keywords internal
#' @export
setClass("PqConnection",
  contains = "DBIConnection",
  slots = list(ptr = "externalptr")
)

#' @export
#' @rdname PqConnection-class
setMethod("dbGetInfo", "PqConnection", function(dbObj, ...) {
  connection_info(dbObj@ptr)
})

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

#' Connect to a PostgreSQL database.
#'
#' Note that manually disconnecting a connection is not necessary with RPostgres;
#' if you delete the object containing the connection, it will be automatcally
#' disconnected during the next GC.
#'
#' @param drv \code{RPostgres::Postgres()}
#' @param dbname Database name. If \code{NULL}, defaults to the user name.
#' @param user,password User name and password. If \code{NULL}, will be
#'   retrieved from \code{PGUSER} and \code{PGPASSWORD} envvars, or from the
#'   appropriate line in \code{~/.pgpass}. See
#'   \url{http://www.postgresql.org/docs/9.4/static/libpq-pgpass.html} for
#'   more details.
#' @param host,port Host and port. If \code{NULL}, will be retrieved from
#'   \code{PGHOST} and \code{PGPORT} env vars.
#' @param service Name of service to connect as.  If \code{NULL}, will be
#'   ignored.  Otherwise, connection parameters will be loaded from the pg_service.conf
#'   file and used.  See \url{http://www.postgresql.org/docs/9.4/static/libpq-pgservice.html}
#'   for details on this file and syntax.
#' @param ... Other name-value pairs that describe additional connection
#'   options as described at
#'   \url{http://www.postgresql.org/docs/9.4/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS}
#' @param conn Connection to disconnect.
#' @export
#' @examples
#' library(DBI)
#' con <- dbConnect(RPostgres::Postgres())
#' dbDisconnect(con)
setMethod("dbConnect", "PqDriver", function(drv, dbname = NULL,
  host = NULL, port = NULL, password = NULL, user = NULL, service = NULL, ...) {

  opts <- unlist(list(dbname = dbname, user = user, password = password,
    host = host, port = as.character(port), service = service, client_encoding = "utf8", ...))
  if (!is.character(opts)) {
    stop("All options should be strings", call. = FALSE)
  }

  if (length(opts) == 0) {
    ptr <- connection_create(character(), character())
  } else {
    ptr <- connection_create(names(opts), as.vector(opts))
  }

  new("PqConnection", ptr = ptr)
})

#' @export
#' @rdname dbConnect-PqDriver-method
setMethod("dbDisconnect", "PqConnection", function(conn, ...) {
  connection_release(conn@ptr)
  TRUE
})

#' Determine database type for R vector.
#'
#' @export
#' @param dbObj Postgres driver or connection.
#' @param obj Object to convert
#' @keywords internal
#' @rdname dbDataType
setMethod("dbDataType", "PqDriver", function(dbObj, obj) {
  if (is.data.frame(obj)) return(callNextMethod(dbObj, obj))
  get_data_type(obj)
})

#' @export
#' @rdname dbDataType
setMethod("dbDataType", "PqConnection", function(dbObj, obj) {
  if (is.data.frame(obj)) return(callNextMethod(dbObj, obj))
  get_data_type(obj)
})

get_data_type <- function(obj) {
  if (is.factor(obj)) return("TEXT")
  if (inherits(obj, "POSIXt")) return("TIMESTAMPTZ")
  if (inherits(obj, "Date")) return("DATE")
  if (inherits(obj, "hms")) return("TIME")
  switch(typeof(obj),
    integer = "INTEGER",
    double = "REAL",
    character = "TEXT",
    logical = "BOOLEAN",
    list = "BYTEA",
    stop("Unsupported type", call. = FALSE)
  )
}
