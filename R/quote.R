#' @include PqConnection.R
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
  res <- SQL(paste0(connection_quote_string(conn@ptr, enc2utf8(x)), "::varchar"))
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
  if (anyNA(x)) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  SQL(connection_quote_identifier(conn@ptr, x))
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "SQL"), function(conn, x, ...) {
  x
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "logical"), function(conn, x, ...) {
  x <- as.character(x)
  x[is.na(x)] <- "NULL"
  SQL(x)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "integer"), function(conn, x, ...) {
  ret <- paste0(as.character(x), "::int4")
  ret[is.na(x)] <- "NULL"
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "numeric"), function(conn, x, ...) {
  ret <- paste0(as.character(x), "::float8")
  ret[is.na(x)] <- "NULL"
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "factor"), function(conn, x, ...) {
  dbQuoteLiteral(conn, as.character(x))
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "Date"), function(conn, x, ...) {
  ret <- paste0("'", as.character(x), "'::date")
  ret[is.na(x)] <- "NULL"
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "POSIXt"), function(conn, x, ...) {
  ret <- paste0("'", as.character(x), "'::timestamp")
  ret[is.na(x)] <- "NULL"
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "difftime"), function(conn, x, ...) {
  ret <- paste0(as.character(x), "::time")
  ret[is.na(x)] <- "NULL"
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbQuoteLiteral", c("PqConnection", "list"), function(conn, x, ...) {
  quote_blob(x)
})

# Workaround, remove when blob > 1.1.0 is on CRAN
setOldClass("blob")

#' @export
#' @rdname quote
#' @importFrom blob blob
setMethod("dbQuoteLiteral", c("PqConnection", "blob"), function(conn, x, ...) {
  quote_blob(x)
})

quote_blob <- function(x) {
  blob_data <- vcapply(
    x,
    function(x) {
      if (is.null(x)) "NULL"
      else if (is.raw(x)) paste0("E'\\\\x", paste(format(x), collapse = ""), "'")
      else {
        stop("Lists must contain raw vectors or NULL", call. = FALSE)
      }
    }
  )
  SQL(blob_data)
}
