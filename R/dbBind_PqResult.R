#' @rdname postgres-query
#' @usage NULL
dbBind_PqResult <- function(res, params, ...) {
  if (!is.null(names(params))) {
    stopc("`params` must not be named.")
  }
  if (!is.list(params)) {
    params <- as.list(params)
  }

  params <- factor_to_string(params, warn = TRUE)
  params <- fix_posixt(params, res@conn@timezone)
  params <- difftime_to_hms(params)
  params <- fix_numeric(params)
  params <- prepare_for_binding(params)
  result_bind(res@ptr, params)
  invisible(res)
}

#' @rdname postgres-query
#' @export
setMethod("dbBind", "PqResult", dbBind_PqResult)
