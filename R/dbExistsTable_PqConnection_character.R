#' @rdname postgres-tables
#' @usage NULL
dbExistsTable_PqConnection_character <- function(conn, name, ...) {
  stopifnot(length(name) == 1L)
  name <- dbQuoteIdentifier(conn, name)

  # Convert to identifier
  id <- dbUnquoteIdentifier(conn, name)[[1]]
  exists_table(conn, id)
}

#' @rdname postgres-tables
#' @export
setMethod("dbExistsTable", c("PqConnection", "character"), dbExistsTable_PqConnection_character)
