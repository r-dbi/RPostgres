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
      "SELECT ", null_varchar, " AS schema, table_name AS table FROM INFORMATION_SCHEMA.tables\n",
      "WHERE (table_schema = ANY(current_schemas(true))) AND (table_schema <> 'pg_catalog')\n",
      "UNION ALL\n",
      "SELECT DISTINCT table_schema AS schema, ", null_varchar, " AS table FROM INFORMATION_SCHEMA.tables"
    )
  } else {
    stopifnot("prefix must be Id" = inherits(prefix, "Id"))
    unquoted <- dbUnquoteIdentifier(conn, prefix)
    is_prefix <- vlapply(unquoted, function(x) {
      "schema" %in% names(x@name) && !("table" %in% names(x@name))
    })
    schemas <- vcapply(unquoted[is_prefix], function(x) x@name[["schema"]])
    if (length(schemas) > 0) {
      schema_strings <- dbQuoteString(conn, schemas)
      query <- paste0(
        "SELECT table_schema AS schema, table_name AS table FROM INFORMATION_SCHEMA.tables\n",
        "WHERE ",
        "(table_schema IN (", paste(schema_strings, collapse = ", "), "))"
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
