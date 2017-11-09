#' @include connection.R
NULL

#' Quote postgres strings and identifiers.
#'
#' @param conn A \linkS4class{PqConnection} created by \code{dbConnect()}
#' @param x A character to escaped
#' @param ... Other arguments needed for compatibility with generic
#' @examples
#' library(DBI)
#' con <- dbConnect(RPostgres::Postgres())
#'
#' x <- c("a", "b c", "d'e", "\\f")
#' dbQuoteString(con, x)
#' dbQuoteIdentifier(con, x)
#' @name quote
NULL

#' @export
#' @rdname quote
setMethod("dbQuoteString", c("PqConnection", "character"), function(conn, x, ...) {
  if (length(x) == 0) return(SQL(character()))
  res <- SQL(paste0(connection_escape_string(conn@ptr, enc2utf8(x)), "::varchar"))
  res
})

#' @export
#' @rdname quote
setMethod("dbQuoteString", c("PqConnection", "SQL"), function(conn, x, ...) {
  x
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "character"), function(conn, x, ...) {
  if (any(is.na(x))) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  SQL(connection_escape_identifier(conn@ptr, x))
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "SQL"), function(conn, x, ...) {
  x
})
