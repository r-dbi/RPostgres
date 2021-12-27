# dbSendQuery()
# dbSendStatement()
# dbDataType()
#' @rdname dbDataType
#' @usage NULL
dbDataType_PqConnection <- function(dbObj, obj, ...) {
  if (is.data.frame(obj)) return(vapply(obj, dbDataType, "", dbObj = dbObj))
  get_data_type(obj)
}

#' @rdname dbDataType
#' @export
setMethod("dbDataType", "PqConnection", dbDataType_PqConnection)
