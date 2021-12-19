#' @rdname postgres-transactions
#' @usage NULL
dbRollback_PqConnection <- function(conn, ..., name = NULL) {
  if (is.null(name)) {
    if (!connection_is_transacting(conn@ptr)) {
      stop("Call dbBegin() to start a transaction.", call. = FALSE)
    }
    dbExecute(conn, "ROLLBACK")
    connection_set_transacting(conn@ptr, FALSE)
  } else {
    name_quoted <- dbQuoteIdentifier(conn, name)
    dbExecute(conn, paste0("ROLLBACK TO ", name_quoted))
    dbExecute(conn, paste0("RELEASE SAVEPOINT ", name_quoted))
  }
  invisible(TRUE)
}

#' @rdname postgres-transactions
#' @export
setMethod("dbRollback", "PqConnection", dbRollback_PqConnection)
