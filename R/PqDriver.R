#' @include s4.R
NULL

#' Postgres driver
#'
#' This driver never needs to be unloaded and hence `dbUnload()` is a
#' null-op.
#'
#' @export
#' @useDynLib RPostgres, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @import methods DBI
#' @examples
#' library(DBI)
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
setMethod("dbUnloadDriver", "PqDriver", function(drv, ...) {
  NULL
})

#' @rdname PqResult-class
#' @export
setMethod("dbIsValid", "PqDriver", function(dbObj, ...) {
  TRUE
})
