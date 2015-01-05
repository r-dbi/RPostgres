setClass("PqDriver", contains = "DBIDriver")

#' Postgres driver
#'
#' @aliases PgDriver-class
#' @export
#' @useDynLib rpq
#' @importFrom Rcpp evalCpp
#' @examples
#' rpq::pq()
pq <- function() {
  new("PqDriver")
}

setMethod("show", "PqDriver", function(object) {
  cat("<PqDriver>\n")
})
