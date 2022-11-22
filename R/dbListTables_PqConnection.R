#' @rdname postgres-tables
#' @usage NULL
dbListTables_PqConnection <- function(conn, ...) {
  query <- list_tables(conn = conn, order_by = "table_type, table_name")

  dbGetQuery(conn, query)[["table_name"]]
}

#' @rdname postgres-tables
#' @export
setMethod("dbListTables", "PqConnection", dbListTables_PqConnection)
