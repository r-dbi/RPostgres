#' PostgreSQL results.
#'
#' @keywords internal
#' @include connection.R
#' @export
setClass("PqResult",
  contains = "DBIResult",
  slots = list(
    ptr = "externalptr",
    sql = "character"
  )
)

#' @rdname PqResult-class
#' @export
setMethod("dbGetStatement", "PqResult", function(res, ...) {
  res@sql
})

#' @rdname PqResult-class
#' @export
setMethod("dbIsValid", "PqResult", function(dbObj, ...) {
  postgres_result_valid(dbObj@ptr)
})

#' @rdname PqResult-class
#' @export
setMethod("show", "PqResult", function(object) {
  cat("<PqResult>\n")
  if(!dbIsValid(object)){
    cat("EXPIRED\n")
  } else {
    cat("  SQL  ", dbGetStatement(object), "\n", sep = "")
#
#     done <- if (dbHasCompleted(object)) "complete" else "incomplete"
#     cat("  ROWS Fetched: ", dbGetRowCount(object), " [", done, "]\n", sep = "")
#     cat("       Changed: ", dbGetRowsAffected(object), "\n", sep = "")
  }
  invisible(NULL)
})

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
  statement <- enc2utf8(statement)

  new("PqResult",
    ptr = rpostgres_send_query(conn@ptr, statement),
    sql = statement)
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
