#' @rdname quote
#' @usage NULL
dbQuoteString_PqConnection_character <- function(conn, x, ...) {
  if (length(x) == 0) return(SQL(character()))
  if (is(conn, "RedshiftConnection")) {
    out <- paste0("'", gsub("(['\\\\])", "\\1\\1", enc2utf8(x)), "'")
    out[is.na(x)] <- "NULL::varchar(max)"
  } else {
    out <- connection_quote_string(conn@ptr, enc2utf8(x))
  }
  SQL(out)
}

#' @rdname quote
#' @export
setMethod("dbQuoteString", c("PqConnection", "character"), dbQuoteString_PqConnection_character)
