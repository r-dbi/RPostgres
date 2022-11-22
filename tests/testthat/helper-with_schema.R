#' Run an expression that creates a schema and clean up afterwards.
#'
#' @param con PqConnection. The database connection.
#' @param schema character. The schema name.
#' @param expr expression. The R expression to execute.
#' @return the return value of the \code{expr}.
with_schema <- function(con, schema, expr) {
  on.exit(
    DBI::dbExecute(con, paste0("DROP SCHEMA IF EXISTS ", schema)),
    add = TRUE
  )
  DBI::dbExecute(con, paste0("CREATE SCHEMA IF NOT EXISTS ", schema))
  force(expr)
}
