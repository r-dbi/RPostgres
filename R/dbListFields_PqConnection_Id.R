#' @rdname postgres-tables
#' @usage NULL
dbListFields_PqConnection_Id <- function(conn, name, ...) {
  list_fields(conn, id = name)
}

#' @rdname postgres-tables
#' @export
setMethod("dbListFields", c("PqConnection", "Id"), dbListFields_PqConnection_Id)
