#' Redshift driver/connection
#'
#' Use `Redshift()` instead of `Postgres()` to connect to an AWS Redshift cluster.
#' All methods in \pkg{RPostgres} and downstream packages can be called on such connections.
#' Some have different behavior for Redshift connections, to ensure better interoperability.
#'
#' @inheritParams Postgres
#' @export
Redshift <- function() {
  new("RedshiftDriver")
}

#' @export
#' @rdname Redshift
setClass("RedshiftDriver", contains = "PqDriver")

#' @export
#' @rdname Redshift
setClass("RedshiftConnection", contains = "PqConnection")

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
