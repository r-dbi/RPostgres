#' RPostgres error conditions
#'
#' @description
#' When a server-side error occurs, RPostgres raises a classed condition that
#' carries PostgreSQL's `SQLSTATE` code and the diagnostic fields reported by
#' `libpq`. The class vector of the condition is
#' `c("RPostgres_error_<SQLSTATE>", "RPostgres_error", "error", "condition")`,
#' so handlers can dispatch on a specific code or on all RPostgres errors.
#'
#' The following fields are attached to the condition object (any of them may be
#' `NULL` if `libpq` did not supply a value): `sqlstate`, `hint`, `detail`,
#' `context`, `table`, `column`, `datatype`, `constraint`, and `schema`. They map
#' to the corresponding `PG_DIAG_*` fields reported by libpq's
#' `PQresultErrorField()`.
#'
#' Errors that are not associated with a server result (for example a lost
#' connection) still carry the `RPostgres_error` class but have no `sqlstate`.
#'
#' @examples
#' \dontrun{
#' # Dispatch on a specific SQLSTATE
#' tryCatch(
#'   dbGetQuery(con, "SELECT * FROM no_such_table"),
#'   RPostgres_error_42P01 = function(e) e$sqlstate
#' )
#'
#' # Read the SQLSTATE programmatically
#' cnd <- tryCatch(
#'   dbGetQuery(con, "SELECT * FROM no_such_table"),
#'   RPostgres_error = identity
#' )
#' cnd$sqlstate
#' }
#' @name RPostgres-conditions
NULL

# Build a classed condition carrying libpq diagnostic fields and signal it.
# Called from C++ via cpp11::package("RPostgres")[["signal_pq_error"]].
# `fields` is a named list; any element may be NULL (absent libpq field).
signal_pq_error <- function(message, fields = list()) {
  sqlstate <- fields$sqlstate

  # errorCondition() appends "error" and "condition" itself.
  classes <- c(
    if (!is.null(sqlstate) && nzchar(sqlstate)) {
      paste0("RPostgres_error_", sqlstate)
    },
    "RPostgres_error"
  )

  cnd <- errorCondition(
    message = message,
    class = classes,
    call = NULL,
    sqlstate = fields$sqlstate,
    hint = fields$hint,
    detail = fields$detail,
    context = fields$context,
    table = fields$table,
    column = fields$column,
    datatype = fields$datatype,
    constraint = fields$constraint,
    schema = fields$schema
  )

  stop(cnd)
}
