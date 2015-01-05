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
