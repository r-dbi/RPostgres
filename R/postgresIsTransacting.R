#' Return whether a transaction is ongoing
#'
#' Detect whether the transaction is active for the given connection. A
#' transaction might be started with [dbBegin()] or wrapped within
#' [DBI::dbWithTransaction()].
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @return A boolean, indicating if a transaction is ongoing.
postgresIsTransacting <- function(conn) {
  connection_is_transacting(conn)
}