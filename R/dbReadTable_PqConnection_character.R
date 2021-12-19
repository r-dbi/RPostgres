#' @param check.names If `TRUE`, the default, column names will be
#'   converted to valid R identifiers.
#' @rdname postgres-tables
#' @usage NULL
dbReadTable_PqConnection_character <- function(conn, name, ..., check.names = TRUE, row.names = FALSE) {
  if (is.null(row.names)) row.names <- FALSE
  if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L) {
    stopc("`row.names` must be a logical scalar or a string")
  }

  if (!is.logical(check.names) || length(check.names) != 1L) {
    stopc("`check.names` must be a logical scalar")
  }

  name <- dbQuoteIdentifier(conn, name)
  out <- dbGetQuery(conn, paste("SELECT * FROM ", name), row.names = row.names)

  if (check.names) {
    names(out) <- make.names(names(out), unique = TRUE)
  }

  out
}

#' @rdname postgres-tables
#' @export
setMethod("dbReadTable", c("PqConnection", "character"), dbReadTable_PqConnection_character)
