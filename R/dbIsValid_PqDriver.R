#' @rdname PqResult-class
#' @usage NULL
dbIsValid_PqDriver <- function(dbObj, ...) {
  TRUE
}

#' @rdname PqResult-class
#' @export
setMethod("dbIsValid", "PqDriver", dbIsValid_PqDriver)
