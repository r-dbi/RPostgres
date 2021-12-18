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
