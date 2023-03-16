#' Postgres driver
#'
#' @export
#' @useDynLib RPostgres, .registration = TRUE
#' @import methods DBI
Postgres <- function() {
  new("PqDriver")
}

#' PqDriver and methods.
#'
#' @export
#' @keywords internal
setClass("PqDriver", contains = "DBIDriver")

# Set during installation time for the correct library
PACKAGE_VERSION <- utils::packageVersion(utils::packageName())
