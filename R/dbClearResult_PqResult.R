#' @rdname postgres-query
#' @usage NULL
dbClearResult_PqResult <- function(res, ...) {
  if (!dbIsValid(res)) {
    warningc("Expired, result set already closed")
    return(invisible(TRUE))
  }
  result_release(res@ptr)
  invisible(TRUE)
}

#' @rdname postgres-query
#' @export
setMethod("dbClearResult", "PqResult", dbClearResult_PqResult)
