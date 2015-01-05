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
  con_info(dbObj@ptr)
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
#' Note that manually disconnecting a connection is not necessary with rpq; if
#' you delete the object containing the connection, it will be automatcally
#' disconnected during the next GC.
#'
#' @param drv \code{rpg::pq()}
#' @param dbname Database name. If \code{NULL}, defaults to the user name.
#' @param user,password User name and password. If \code{NULLL}, will be
#'   retrieved from \code{PGUSER} and \code{PGPASSWORD} envvars, or from the
#'   appropriate line in \code{~/.pgpass}. See below for details.
#' @param host,port Host and port. If \code{NULL}, will be retrieved from
#'   \code{PGHOST} and \code{PGPORT} env vars.
#' @param ... Other name-value pairs that describe additional connection
#'   options as described at
#'   \url{http://www.postgresql.org/docs/9.4/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS}
#' @param conn Connection to disconnect.
#' @export
#' @examples
#' con <- dbConnect(pq())
#' dbDisconnect(con)
setMethod("dbConnect", "PqDriver", function(drv, dbname = NULL,
  host = NULL, port = NULL, password = NULL, user = NULL, ...) {

  opts <- unlist(list(dbname = dbname, user = user, password = password,
    host = host, port = as.character(port)))
  if (!is.character(opts)) {
    stop("All options should be strings", call. = FALSE)
  }

  if (length(opts) == 0) {
    ptr <- connect(character(), character())
  } else {
    ptr <- connect(names(opts), as.vector(opts))
  }

  new("PqConnection", ptr = ptr)
})

#' @export
#' @rdname dbConnect-PqDriver-method
setMethod("dbDisconnect", "PqConnection", function(conn, ...) {
  disconnect(conn@ptr)
  TRUE
})

#' Get more details of error related to exception.
#'
#' @param conn A \code{PQConnection} object
#' @param ... Needed for compatibility with generic; otherwise ignored.
#' @export
#' @examples
#' con <- dbConnect(rpq::pq())
#' try(dbSendQuery(con, "BLAH"), silent = TRUE)
#' dbGetException(con)
#'
#' try(dbSendQuery(con, "SELECT 1 + 'a'"), silent = TRUE)
#' dbGetException(con)
setMethod("dbGetException", "PqConnection", function(conn, ...) {
  exception_info(conn@ptr)
})
