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


# Set during installation time for the correct library
PACKAGE_VERSION <- utils::packageVersion(utils::packageName())

#' @export
setMethod("dbGetInfo", "PqDriver", function(dbObj, ...) {
  client_version <- client_version()
  major <- client_version %/% 10000
  minor <- (client_version - major * 10000) %/% 100
  rev <- client_version - major * 10000 - minor * 100

  version <- RSQLite::rsqliteVersion()
  list(
    driver.version = PACKAGE_VERSION,
    client.version = package_version(paste0(major, ".", minor, ".", rev))
  )
})
