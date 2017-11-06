#' Run an expression that creates and touches a table, then clean up.
#'
#' @param con PqConnection. The database connection.
#' @param tbl character. The table name.
#' @param expr expression. The R expression to execute.
#' @return the return value of the \code{expr}.
with_table <- function(con, tbl, expr) {
  on.exit(dbRemoveTable(con, tbl), add = TRUE)
  force(expr)
}

