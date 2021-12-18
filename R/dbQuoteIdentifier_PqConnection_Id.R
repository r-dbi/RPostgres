#' @rdname quote
#' @usage NULL
dbQuoteIdentifier_PqConnection_Id <- function(conn, x, ...) {
  stopifnot(all(names(x@name) %in% c("catalog", "schema", "table")))
  stopifnot(!anyDuplicated(names(x@name)))

  ret <- ""
  if ("catalog" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["catalog"]]), ".")
  }
  if ("schema" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["schema"]]), ".")
  }
  if ("table" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["table"]]))
  }
  SQL(ret)
}

#' @rdname quote
#' @export
setMethod("dbQuoteIdentifier", c("PqConnection", "Id"), dbQuoteIdentifier_PqConnection_Id)
