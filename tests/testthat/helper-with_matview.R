#' Run an expression that creates a materialized view and clean up afterwards.
#'
#' @param con PqConnection. The database connection.
#' @param matview character. The materialized view name.
#' @param query character. A SELECT, TABLE, or VALUES command to populate the
#'   materialized view.
#' @param expr expression. The R expression to execute.
#' @return the return value of the \code{expr}.
#' @seealso https://www.postgresql.org/docs/current/sql-creatematerializedview.html
with_matview <- function(con, matview, query, expr) {
  on.exit(
    DBI::dbExecute(con, paste0("DROP MATERIALIZED VIEW IF EXISTS ", matview)),
    add = TRUE
  )
  dbExecute(
    con,
    paste0(
      "CREATE MATERIALIZED VIEW IF NOT EXISTS ", matview,
      " AS ", query
    )
  )

  force(expr)
}
