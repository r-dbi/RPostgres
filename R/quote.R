#' @include connection.R
NULL

#' Quote postgres strings and identifiers.
#'
#' @param conn A \linkS4class{PqConnection} created by \code{dbConnect()}
#' @param x A character to escaped
#' @param ... Other arguments needed for compatibility with generic
#' @examples
#' con <- dbConnect(rpq::pq())
#'
#' x <- c("a", "b c", "d'e", "\\f")
#' dbQuoteString(con, x)
#' dbQuoteIdentifier(con, x)
#' @name quote
NULL

#' @export
#' @rdname quote
setMethod("dbQuoteString", c("PqConnection", "character"), function(conn, x, ...) {
  SQL(escape_string(conn@ptr, x))
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "character"), function(conn, x, ...) {
  SQL(escape_identifier(conn@ptr, x))
})
