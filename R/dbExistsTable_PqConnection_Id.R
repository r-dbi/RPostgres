#' @rdname postgres-tables
#' @usage NULL
dbExistsTable_PqConnection_Id <- function(conn, name, ...) {
  exists_table(conn, id = name)
}

#' @rdname postgres-tables
#' @export
setMethod(
  "dbExistsTable",
  c("PqConnection", "Id"),
  dbExistsTable_PqConnection_Id
)
