#' @rdname Redshift
#' @usage NULL
dbConnect_RedshiftDriver <- function(
  drv,
  dbname = NULL,
  host = NULL,
  port = NULL,
  password = NULL,
  user = NULL,
  service = NULL,
  ...,
  bigint = c("integer64", "integer", "numeric", "character"),
  check_interrupts = FALSE,
  timezone = "UTC"
) {
  new("RedshiftConnection", callNextMethod())
}

#' @rdname Redshift
#' @export
setMethod("dbConnect", "RedshiftDriver", dbConnect_RedshiftDriver)
