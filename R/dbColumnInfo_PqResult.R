#' @rdname PqResult-class
#' @usage NULL
dbColumnInfo_PqResult <- function(res, ...) {
  rci <- result_column_info(res@ptr)
  rci <- cbind(rci, .typname = type_lookup(rci[[".oid"]], res@conn), stringsAsFactors = FALSE)
  rci$name <- tidy_names(rci$name)
  rci
}

#' @rdname PqResult-class
#' @export
setMethod("dbColumnInfo", "PqResult", dbColumnInfo_PqResult)
