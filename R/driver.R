setClass("PgDriver", contains = "DBIDriver")

#' Postgres driver
#'
#' @aliases PgDriver-class
#' @export
#' @useDynLib rpg
#' @importFrom Rcpp evalCpp
pg <- function() {
  new("PgDriver")
}

setMethod("show", "PgDriver", function(object) {
  cat("<PgDriver>\n")
})
