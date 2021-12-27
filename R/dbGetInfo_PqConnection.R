# dbQuoteString()
# dbQuoteIdentifier()
# dbWriteTable()
# dbReadTable()
# dbListTables()
# dbExistsTable()
# dbListFields()
# dbRemoveTable()
# dbGetInfo()
#' @rdname PqConnection-class
#' @usage NULL
dbGetInfo_PqConnection <- function(dbObj, ...) {
  connection_info(dbObj@ptr)
}

#' @rdname PqConnection-class
#' @export
setMethod("dbGetInfo", "PqConnection", dbGetInfo_PqConnection)
