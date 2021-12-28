#' @name quote
#' @usage NULL
dbQuoteIdentifier_PqConnection_Id <- function(conn, x, ...) {
  components <- c("catalog", "schema", "table", "column")
  stopifnot(all(names(x@name) %in% components))
  stopifnot(!anyDuplicated(names(x@name)))

  ret <- stats::na.omit(x@name[match(components, names(x@name))])
  SQL(paste0(dbQuoteIdentifier(conn, ret), collapse = "."))
}

#' @rdname quote
#' @export
setMethod("dbQuoteIdentifier", c("PqConnection", "Id"), dbQuoteIdentifier_PqConnection_Id)
