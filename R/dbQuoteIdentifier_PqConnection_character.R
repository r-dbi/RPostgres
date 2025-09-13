#' @rdname quote
#' @usage NULL
dbQuoteIdentifier_PqConnection_character <- function(conn, x, ...) {
  if (anyNA(x)) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  SQL(connection_quote_identifier(conn@ptr, x), names = names(x))
}

#' @rdname quote
#' @export
setMethod(
  "dbQuoteIdentifier",
  c("PqConnection", "character"),
  dbQuoteIdentifier_PqConnection_character
)
