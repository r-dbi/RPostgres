#' @rdname postgres-transactions
#' @usage NULL
dbCommit_PqConnection <- function(conn, ..., name = NULL) {
  if (is.null(name)) {
    if (!connection_is_transacting(conn@ptr)) {
      stop("Call dbBegin() to start a transaction.", call. = FALSE)
    }
    dbExecute(conn, "COMMIT")
    connection_set_transacting(conn@ptr, FALSE)
  } else {
    dbExecute(conn, paste0("RELEASE SAVEPOINT ", dbQuoteIdentifier(conn, name)))
  }
  invisible(TRUE)
}

#' @rdname postgres-transactions
#' @export
setMethod("dbCommit", "PqConnection", dbCommit_PqConnection)
