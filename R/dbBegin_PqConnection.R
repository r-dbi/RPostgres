#' @param name If provided, uses the `SAVEPOINT` SQL syntax
#'   to establish, remove (commit) or undo a ßsavepoint.
#' @rdname postgres-transactions
#' @usage NULL
dbBegin_PqConnection <- function(conn, ..., name = NULL) {
  if (is.null(name)) {
    if (connection_is_transacting(conn@ptr)) {
      stop("Nested transactions not supported.", call. = FALSE)
    }
    dbExecute(conn, "BEGIN")
    connection_set_transacting(conn@ptr, TRUE)
  } else {
    if (!connection_is_transacting(conn@ptr)) {
      stop("Savepoints require an active transaction.", call. = FALSE)
    }
    dbExecute(conn, paste0("SAVEPOINT ", dbQuoteIdentifier(conn, name)))
  }
  invisible(TRUE)
}

#' @rdname postgres-transactions
#' @export
setMethod("dbBegin", "PqConnection", dbBegin_PqConnection)
