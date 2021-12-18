#' @description [dbAppendTable()] is overridden because \pkg{RPostgres}
#' uses placeholders of the form `$1`, `$2` etc. instead of `?`.
#' @rdname postgres-tables
#' @usage NULL
dbAppendTable_PqConnection <- function(conn, name, value, copy = NULL, ..., row.names = NULL) {
  stopifnot(is.null(row.names))
  stopifnot(is.data.frame(value))
  db_append_table(conn, name, value, copy = copy, warn = TRUE)
}

#' @rdname postgres-tables
#' @export
setMethod("dbAppendTable", "PqConnection", dbAppendTable_PqConnection)
