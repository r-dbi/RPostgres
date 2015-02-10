#' Postgres driver
#'
#' This driver never needs to be unloaded and hence \code{dbUnload()} is a
#' null-op.
#'
#' @export
#' @useDynLib RPostgres
#' @importFrom Rcpp evalCpp
#' @import methods DBI
#' @examples
#' RPostgres::Postgres()
Postgres <- function() {
  new("PqDriver")
}

#' PqDriver and methods.
#'
#' @export
#' @keywords internal
setClass("PqDriver", contains = "DBIDriver")

#' @export
#' @rdname PqDriver-class
setMethod("show", "PqDriver", function(object) {
  cat("<PqDriver>\n")
})

#' @export
#' @rdname PqDriver-class
setMethod("dbUnloadDriver", "PqDriver", function(drv, ...) {
  NULL
})

