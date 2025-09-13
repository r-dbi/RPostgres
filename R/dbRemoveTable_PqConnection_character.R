#' @rdname postgres-tables
#' @param temporary If `TRUE`, only temporary tables are considered.
#' @param fail_if_missing If `FALSE`, `dbRemoveTable()` succeeds if the
#'   table doesn't exist.
#' @usage NULL
dbRemoveTable_PqConnection_character <- function(
  conn,
  name,
  ...,
  temporary = FALSE,
  fail_if_missing = TRUE
) {
  name <- dbQuoteIdentifier(conn, name)
  if (fail_if_missing) {
    extra <- ""
  } else {
    extra <- "IF EXISTS "
  }
  if (temporary) {
    temp_schema <- find_temp_schema(conn, fail_if_missing)
    if (is.null(temp_schema)) {
      return(invisible(TRUE))
    }
    extra <- paste0(extra, temp_schema, ".")
  }
  dbExecute(conn, paste0("DROP TABLE ", extra, name))
  invisible(TRUE)
}

#' @rdname postgres-tables
#' @export
setMethod(
  "dbRemoveTable",
  c("PqConnection", "character"),
  dbRemoveTable_PqConnection_character
)
