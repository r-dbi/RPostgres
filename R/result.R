#' PostgreSQL results.
#'
#' @keywords internal
#' @include connection.R
#' @export
setClass("PqResult",
  contains = "DBIResult",
  slots = list(ptr = "externalptr")
)

#' Send a query to the database.
#'
#' @param conn A \code{\linkS4class{PqConnection}} created by \code{dbConnect}.
#' @param statement An SQL string to execture
#' @param ... Another arguments needed for compatibility with generic (
#'   currently ignored).
#' @return On failure throws an error; otherwise returns an object
#'   of class \code{PqResult}.
#' @export
#' @examples
#' con <- dbConnect(rpq::pq())
#' dbSendQuery(con, "SELECT * FROM pg_catalog.pg_tables")
setMethod("dbSendQuery", "PqConnection", function(conn, statement, ...) {
  exec(conn@ptr, statement)
  new("PqResult", ptr = conn@ptr)
})

#' Fetch results into a data frame
#'
#' @param res Code a \linkS4class{PqResult} produced by
#'   \code{\link[DBI]{dbSendQuery}}.
#' @param n Number of rows to return. Currently must always return all data.
#' @param ... Needed for compatibility with generic; currently ignored.
#' @export
setMethod("dbFetch", "PqResult", function(res, n = -1, ...) {
  if (!identical(as.integer(n), -1L)) {
    warning("Always retrieves all data")
  }

  fetch(res@ptr)
})

#' @rdname dbFetch-PqResult-method
#' @export
setMethod("dbHasCompleted", "PqResult", function(res, ...) {
  is_complete(res@ptr)
})

#' @rdname dbFetch-PqResult-method
#' @export
setMethod("dbClearResult", "PqResult", function(res, ...) {
  clear_result(res@ptr)
  TRUE
})
