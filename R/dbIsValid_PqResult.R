#' @rdname PqResult-class
#' @usage NULL
dbIsValid_PqResult <- function(dbObj, ...) {
  result_valid(dbObj@ptr)
}

#' @rdname PqResult-class
#' @export
setMethod("dbIsValid", "PqResult", dbIsValid_PqResult)
