#' @name quote
#' @usage NULL
dbQuoteIdentifier_PqConnection_Id <- function(conn, x, ...) {
  SQL(paste0(dbQuoteIdentifier(conn, x@name), collapse = "."))
}

#' @rdname quote
#' @export
setMethod("dbQuoteIdentifier", c("PqConnection", "Id"), dbQuoteIdentifier_PqConnection_Id)
