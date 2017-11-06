#' Execute an R expression with access to a database connection.
#'
#' @param expr expression. Any R expression.
#' @param con PqConnection. A database connection, by default.
#'    \code{dbConnect(RPostgres::Postgres())}.
#' @return the return value of the evaluated \code{expr}.
with_database_connection <- function(expr, con = dbConnect(RPostgres::Postgres())) {
  context <- list2env(list(con = con), parent = parent.frame())
  eval(substitute(expr), envir = context)
}

