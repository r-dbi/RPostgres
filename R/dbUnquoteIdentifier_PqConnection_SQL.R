#' @rdname quote
#' @usage NULL
dbUnquoteIdentifier_PqConnection_SQL <- function(conn, x, ...) {
  id_rx <- '(?:"((?:[^"]|"")+)"|([^". ]+))'

  rx <- paste0(
    "^",
    "(?:|(?:|",
    id_rx,
    "[.])",
    id_rx,
    "[.])",
    "(?:|",
    id_rx,
    ")",
    "$"
  )

  bad <- grep(rx, x, invert = TRUE)
  if (length(bad) > 0) {
    stop("Can't unquote ", x[bad[[1]]], call. = FALSE)
  }
  catalog <- gsub(rx, "\\1\\2", x)
  catalog <- gsub('""', '"', catalog)
  schema <- gsub(rx, "\\3\\4", x)
  schema <- gsub('""', '"', schema)
  table <- gsub(rx, "\\5\\6", x)
  table <- gsub('""', '"', table)

  ret <- Map(catalog, schema, table, f = as_table)
  names(ret) <- names(x)
  ret
}

#' @rdname quote
#' @export
setMethod(
  "dbUnquoteIdentifier",
  c("PqConnection", "SQL"),
  dbUnquoteIdentifier_PqConnection_SQL
)
