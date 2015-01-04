setClass("PgDriver", contains = "DBIDriver")

#' Postgres driver
#'
#' @aliases PgDriver-class
#' @export
pg <- function() {
  new("PgDriver")
}

setMethod("show", "PgDriver", function(object) {
  cat("<PgDriver>\n")
})
