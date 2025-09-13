#' @param immediate If `TRUE`, uses the `PGsendQuery()` API instead of `PGprepare()`.
#'   This allows to pass multiple statements and turns off the ability to pass parameters.
#'
#' @section Multiple queries and statements:
#' With `immediate = TRUE`, it is possible to pass multiple queries or statements,
#' separated by semicolons.
#' For multiple statements, the resulting value of [dbGetRowsAffected()]
#' corresponds to the total number of affected rows.
#' If multiple queries are used, all queries must return data with the same
#' column names and types.
#' Queries and statements can be mixed.
#' @rdname postgres-query
#' @usage NULL
dbSendQuery_PqConnection <- function(
  conn,
  statement,
  params = NULL,
  ...,
  immediate = FALSE
) {
  stopifnot(is.character(statement))

  statement <- enc2utf8(statement)

  rs <- new(
    "PqResult",
    conn = conn,
    ptr = result_create(conn@ptr, statement, immediate),
    sql = statement,
    bigint = conn@bigint
  )

  if (!is.null(params)) {
    dbBind(rs, params)
  }

  rs
}

#' @rdname postgres-query
#' @export
setMethod("dbSendQuery", "PqConnection", dbSendQuery_PqConnection)
