#' @inheritParams DBI::dbListObjects
#' @rdname postgres-tables
#' @usage NULL
dbListObjects_PqConnection_ANY <- function(conn, prefix = NULL, ...) {
  query <- NULL
  is_redshift <- is(conn, "RedshiftConnection")

  if (is.null(prefix)) {
    if (is_redshift) {
      # On Redshift, UNION ALL with NULL::text fails
      null_varchar <- "NULL::varchar(max)"
    } else {
      null_varchar <- "NULL::text"
    }
    query <- paste0(
      "SELECT ", null_varchar, " AS schema, table_name AS table FROM ( \n",
      list_tables(conn = conn, order_by = "table_type, table_name"),
      ") as table_query \n",
      "UNION ALL\n",
      "SELECT DISTINCT table_schema AS schema, ", null_varchar, " AS table FROM ( \n",
      list_tables(conn = conn, where_schema = "true"),
      ") as schema_query;"
    )
  } else {
    if (!is.list(prefix)) prefix <- list(prefix)
    stopifnot("All prefix must be Id()" = vlapply(prefix, is, "Id"))
    is_prefix <- vlapply(prefix, function(x) {
      "schema" %in% names(x@name) && !("table" %in% names(x@name))
    })
    schemas <- vcapply(prefix[is_prefix], function(x) x@name[["schema"]])
    if (length(schemas) > 0) {
      schema_strings <- dbQuoteString(conn, schemas)
      where_schema <-
        paste0(
          "table_schema IN (",
          paste(schema_strings, collapse = ", "),
          ") \n"
        )
      query <- paste0(
        "SELECT table_schema AS schema, table_name AS table FROM ( \n",
        list_tables(
          conn = conn,
          where_schema = where_schema,
          order_by = "table_type, table_name"
        ),
        ") as table_query"
      )
    }
  }

  if (is.null(query)) {
    res <- data.frame(schema = character(), table = character(), stringsAsFactors = FALSE)
  } else {
    res <- dbGetQuery(conn, query)
  }

  is_prefix <- !is.na(res$schema) & is.na(res$table)
  tables <- Map("", res$schema, res$table, f = as_table)

  ret <- data.frame(
    table = I(unname(tables)),
    is_prefix = is_prefix,
    stringsAsFactors = FALSE
  )
  ret
}

#' @rdname postgres-tables
#' @export
setMethod("dbListObjects", c("PqConnection", "ANY"), dbListObjects_PqConnection_ANY)
