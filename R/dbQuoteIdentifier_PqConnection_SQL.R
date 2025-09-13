#' @rdname quote
#' @usage NULL
dbQuoteIdentifier_PqConnection_SQL <- function(conn, x, ...) {
  x
}

#' @rdname quote
#' @export
setMethod(
  "dbQuoteIdentifier",
  c("PqConnection", "SQL"),
  dbQuoteIdentifier_PqConnection_SQL
)
