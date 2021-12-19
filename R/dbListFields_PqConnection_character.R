#' @rdname postgres-tables
#' @usage NULL
dbListFields_PqConnection_character <- function(conn, name, ...) {
  quoted <- dbQuoteIdentifier(conn, name)
  id <- dbUnquoteIdentifier(conn, quoted)[[1]]@name

  list_fields(conn, id)
}

#' @rdname postgres-tables
#' @export
setMethod("dbListFields", c("PqConnection", "character"), dbListFields_PqConnection_character)
