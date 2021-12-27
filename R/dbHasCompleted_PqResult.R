#' @rdname postgres-query
#' @usage NULL
dbHasCompleted_PqResult <- function(res, ...) {
  result_has_completed(res@ptr)
}

#' @rdname postgres-query
#' @export
setMethod("dbHasCompleted", "PqResult", dbHasCompleted_PqResult)
