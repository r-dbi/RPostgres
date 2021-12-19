#' @param res Code a [PqResult-class] produced by
#'   [DBI::dbSendQuery()].
#' @param n Number of rows to return. If less than zero returns all rows.
#' @inheritParams DBI::sqlRownamesToColumn
#' @rdname postgres-query
#' @usage NULL
dbFetch_PqResult <- function(res, n = -1, ..., row.names = FALSE) {
  if (length(n) != 1) stopc("n must be scalar")
  if (n < -1) stopc("n must be nonnegative or -1")
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stopc("n must be a whole number")
  ret <- sqlColumnToRownames(result_fetch(res@ptr, n = n), row.names)
  ret <- convert_bigint(ret, res@bigint)
  ret <- finalize_types(ret, res@conn)
  ret <- fix_timezone(ret, res@conn)
  set_tidy_names(ret)
}

#' @rdname postgres-query
#' @export
setMethod("dbFetch", "PqResult", dbFetch_PqResult)
