#' @rdname quote
#' @usage NULL
dbQuoteString_PqConnection_SQL <- function(conn, x, ...) {
  x
}

#' @rdname quote
#' @export
setMethod("dbQuoteString", c("PqConnection", "SQL"), dbQuoteString_PqConnection_SQL)
