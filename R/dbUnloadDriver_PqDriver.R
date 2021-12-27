#' @rdname PqDriver-class
#' @usage NULL
dbUnloadDriver_PqDriver <- function(drv, ...) {
  NULL
}

#' @rdname PqDriver-class
#' @export
setMethod("dbUnloadDriver", "PqDriver", dbUnloadDriver_PqDriver)
