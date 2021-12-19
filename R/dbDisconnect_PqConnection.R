# dbDisconnect() (after dbConnect() to maintain order in documentation)
#' @rdname Postgres
#' @usage NULL
dbDisconnect_PqConnection <- function(conn, ...) {
  connection_release(conn@ptr)
  invisible(TRUE)
}

#' @rdname Postgres
#' @export
setMethod("dbDisconnect", "PqConnection", dbDisconnect_PqConnection)
