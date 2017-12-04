#' Transaction management.
#'
#' `dbBegin()` starts a transaction. `dbCommit()` and `dbRollback()`
#' end the transaction by either committing or rolling back the changes.
#'
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @param ... Unused, for extensibility.
#' @return A boolean, indicating success or failure.
#' @examples
#' # For running the examples on systems without PostgreSQL connection:
#' run <- postgresHasDefault()
#'
#' library(DBI)
#' if (run) con <- dbConnect(RPostgres::Postgres())
#' if (run) dbWriteTable(con, "USarrests", datasets::USArrests, temporary = TRUE)
#' if (run) dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#'
#' if (run) dbBegin(con)
#' if (run) dbExecute(con, 'DELETE from "USarrests" WHERE "Murder" > 1')
#' if (run) dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#' if (run) dbRollback(con)
#'
#' # Rolling back changes leads to original count
#' if (run) dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#'
#' if (run) dbRemoveTable(con, "USarrests")
#' if (run) dbDisconnect(con)
#' @name postgres-transactions
NULL

#' @export
#' @rdname postgres-transactions
setMethod("dbBegin", "PqConnection", function(conn, ...) {
  if (connection_is_transacting(conn@ptr)) {
    stop("Nested transactions not supported.", call. = FALSE)
  }

  dbExecute(conn, "BEGIN")
  connection_set_transacting(conn@ptr, TRUE)
  invisible(TRUE)
})

#' @export
#' @rdname postgres-transactions
setMethod("dbCommit", "PqConnection", function(conn, ...) {
  if (!connection_is_transacting(conn@ptr)) {
    stop("Call dbBegin() to start a transaction.", call. = FALSE)
  }
  dbExecute(conn, "COMMIT")
  connection_set_transacting(conn@ptr, FALSE)
  invisible(TRUE)
})

#' @export
#' @rdname postgres-transactions
setMethod("dbRollback", "PqConnection", function(conn, ...) {
  if (!connection_is_transacting(conn@ptr)) {
    stop("Call dbBegin() to start a transaction.", call. = FALSE)
  }
  dbExecute(conn, "ROLLBACK")
  connection_set_transacting(conn@ptr, FALSE)
  invisible(TRUE)
})
