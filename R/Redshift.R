#' Redshift driver/connection
#'
#' Redshift currently uses all the same method as Postgres, but allows
#' provides an extension point for future methods and downstream packages.
#'
#' @export
#' @useDynLib RPostgres, .registration = TRUE
#' @importFrom Rcpp sourceCpp
#' @import methods DBI
Redshift <- function() {
  new("RedshiftDriver")
}

#' @export
#' @rdname Redshift
setClass("RedshiftDriver", contains = "PqDriver")

#' @export
#' @rdname Redshift
setClass("RedshiftConnection",
  contains = "PqConnection",
)

#' @export
#' @rdname Redshift
setMethod("dbConnect", "RedshiftDriver",
  function(drv, dbname = NULL,
           host = NULL, port = NULL, password = NULL, user = NULL, service = NULL, ...,
           bigint = c("integer64", "integer", "numeric", "character"),
           check_interrupts = FALSE, timezone = "UTC") {

    new("RedshiftConnection", callNextMethod())
  }
)
