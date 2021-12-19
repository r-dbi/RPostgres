#' @rdname postgres-tables
#' @usage NULL
dbListTables_PqConnection <- function(conn, ...) {
  query <- paste0(
    "SELECT table_name FROM INFORMATION_SCHEMA.tables ",
    "WHERE ",
    "(table_schema = ANY(current_schemas(true))) AND (table_schema <> 'pg_catalog')"
  )
  dbGetQuery(conn, query)[[1]]
}

#' @rdname postgres-tables
#' @export
setMethod("dbListTables", "PqConnection", dbListTables_PqConnection)
