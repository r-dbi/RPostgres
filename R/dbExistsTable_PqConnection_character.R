#' @rdname postgres-tables
#' @usage NULL
dbExistsTable_PqConnection_character <- function(conn, name, ...) {
  stopifnot(length(name) == 1L)
  # use (Un)QuoteIdentifier roundtrip instead of Id(table = name)
  # so that quoted names (possibly incl. schema) can be passed to `name` e.g.
  # name = dbQuoteIdentifier(conn, Id(schema = "sname", table = "tname"))
  quoted <- dbQuoteIdentifier(conn, name)
  id <- dbUnquoteIdentifier(conn, quoted)[[1]]
  exists_table(conn, id)
}

#' @rdname postgres-tables
#' @export
setMethod("dbExistsTable", c("PqConnection", "character"), dbExistsTable_PqConnection_character)
