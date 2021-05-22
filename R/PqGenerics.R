# PostgreSQL-specific features and functions

#' List remote tables
#'
#' Returns the unquoted names of remote tables and table-like objects accessible
#' through this connection.
#' This includes foreign and partitioned tables, (materialized) views, as well
#' as temporary objects.
#'
#' @inheritParams postgres-tables
#'
#' @family PqConnection generics
#'
#' @examples
#' # For running the examples on systems without PostgreSQL connection:
#' run <- postgresHasDefault()
#'
#' library(DBI)
#' if (run) con <- dbConnect(RPostgres::Postgres())
#' if (run) pqListTables(con)
#'
#' if (run) dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' if (run) pqListTables(con)
#'
#' if (run) dbDisconnect(con)
#'
#' @export
setGeneric("pqListTables",
           def = function(conn, ...) standardGeneric("pqListTables"),
           valueClass = "character"
)

#' @rdname pqListTables
#' @export
setMethod("pqListTables", "PqConnection", function(conn) {
  query <- list_tables_sql(conn = conn, order_by = "cl.relkind, cl.relname")

  dbGetQuery(conn, query)[["relname"]]
})

list_tables_sql <- function(conn, where_schema = NULL, where_table = NULL, order_by = NULL) {
  major_server_version <- dbGetInfo(conn)$db.version %/% 10000

  query <- paste0(
    # pg_class docs: https://www.postgresql.org/docs/current/catalog-pg-class.html
    "SELECT n.nspname, cl.relname \n",
    "FROM pg_class AS cl \n",
    "JOIN pg_namespace AS n ON cl.relnamespace = n.oid \n",
    # Return only objects (relations) which the current user may access
    # https://www.postgresql.org/docs/current/functions-info.html
    "WHERE (pg_has_role(cl.relowner, 'USAGE'::text) \n",
    "  OR has_table_privilege(cl.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) \n",
    "  OR has_any_column_privilege(cl.oid, 'SELECT, INSERT, UPDATE, REFERENCES'::text) \n",
    ") \n"
  )

  # which kind of objects should be returned?
  if (major_server_version >= 10) {
    # relkind = 'p' and relispartition only supported from v10 onwards
    query <- paste0(
      query,
      # r = ordinary table, v = view, m = materialized view, f = foreign table,
      # p = partitioned table
      "AND (cl.relkind IN ('r', 'v', 'm', 'f', 'p')) \n",
      "AND NOT cl.relispartition \n" # do not return partitions
    )
  } else {
    query <- paste0(
      query,
      "AND (cl.relkind IN ('r', 'v', 'm', 'f')) \n"
    )
  }

  if (is.null(where_schema)) {
    # all schemas in the search path without implicitly-searched system schemas
    # such as pg_catalog
    query <- paste0(
      query,
      "AND (n.nspname = ANY (current_schemas(false))) \n"
    )
  } else {
    query <- paste0(query, where_schema)
  }

  if (!is.null(where_table)) query <- paste0(query, where_table)

  if (!is.null(order_by)) query <- paste0(query, "ORDER BY ", order_by)

  query
}
#' Does a table exist?
#'
#' Returns if a table or (materialized) view given by name exists in the
#' database.
#'
#' @inheritParams postgres-tables
#'
#' @family PqConnection generics
#'
#' @examples
#' # For running the examples on systems without PostgreSQL connection:
#' run <- postgresHasDefault()
#'
#' library(DBI)
#' if (run) con <- dbConnect(RPostgres::Postgres())
#' if (run) pqExistsTable(con, "mtcars")
#'
#' if (run) dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' if (run) pqExistsTable(con, "mtcars")
#'
#' if (run) dbDisconnect(con)
#'
#' @export
setGeneric("pqExistsTable",
           def = function(conn, name, ...) standardGeneric("pqExistsTable"),
           valueClass = "logical"
)

#' @rdname pqExistsTable
#' @export
setMethod("pqExistsTable", c("PqConnection", "character"), function(conn, name, ...) {
  stopifnot(length(name) == 1L)
  # use (Un)QuoteIdentifier roundtrip instead of Id(table = name)
  # so that quoted names (possibly incl. schema) can be passed to `name` e.g.
  # name = dbQuoteIdentifier(conn, Id(schema = "sname", table = "tname"))
  name <- dbQuoteIdentifier(conn, name)
  id <- dbUnquoteIdentifier(conn, name)[[1]]
  pq_exists_table(conn, id)
})

#' @export
#' @rdname postgres-tables
setMethod("pqExistsTable", c("PqConnection", "Id"), function(conn, name, ...) {
  pq_exists_table(conn, id = name)
})

pq_exists_table <- function(conn, id) {
  name <- id@name
  stopifnot("table" %in% names(name))
  table_name <- dbQuoteString(conn, name[["table"]])
  where_table <- paste0("AND cl.relname = ", table_name, "\n")

  if ("schema" %in% names(name)) {
    schema_name <- dbQuoteString(conn, name[["schema"]])
    where_schema <- paste0("AND n.nspname = ", schema_name, "\n")
  } else {
    where_schema <- NULL
  }
  query <- paste0(
    "SELECT EXISTS ( \n",
    list_tables_sql(conn, where_schema = where_schema, where_table = where_table),
    ")"
  )
  dbGetQuery(conn, query)[[1]]
}

#' List remote objects
#'
#' Returns the names of remote objects accessible through this connection as a
#' data frame.
#' This includes foreign and partitioned tables, (materialized) views, as well
#' as temporary tables.
#' Compared to [dbListTables()], this method also enumerates tables and views
#' in schemas, and returns fully qualified identifiers to access these objects.
#' This allows exploration of all database objects available to the current
#' user, including those that can only be accessed by giving the full namespace.
#'
#' @inheritParams postgres-tables
#'
#' @family PqConnection generics
#'
#' @examples
#' # For running the examples on systems without PostgreSQL connection:
#' run <- postgresHasDefault()
#'
#' library(DBI)
#' if (run) con <- dbConnect(RPostgres::Postgres())
#' if (run) pqListObjects(con)
#'
#' if (run) dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' if (run) pqListObjects(con)
#'
#' if (run) dbDisconnect(con)
#'
#' @export
setGeneric("pqListObjects",
           def = function(conn, prefix = NULL, ...) standardGeneric("pqListObjects"),
           valueClass = "data.frame"
)

#' @rdname pqListObjects
#' @export
setMethod("pqListObjects", c("PqConnection", "ANY"), function(conn, prefix = NULL, ...) {
  query <- NULL
  if (is.null(prefix)) {
    query <- list_tables_sql(conn = conn, order_by = "cl.relkind, cl.relname")
    query <- paste0(
      "SELECT NULL AS schema, relname AS table FROM ( \n",
      query,
      ") as table_query \n",
      "UNION ALL \n",
      "SELECT schema_name AS schema, NULL AS table \n",
      "FROM INFORMATION_SCHEMA.schemata;"
    )
  } else {
    unquoted <- dbUnquoteIdentifier(conn, prefix)
    is_prefix <- vlapply(unquoted, function(x) { "schema" %in% names(x@name) && !("table" %in% names(x@name)) })
    schemas <- vcapply(unquoted[is_prefix], function(x) x@name[["schema"]])
    if (length(schemas) > 0) { # else query is NULL
      schema_strings <- dbQuoteString(conn, schemas)
      where_schema <-
        paste0(
          "AND n.nspname IN (",
          paste(schema_strings, collapse = ", "),
          ")"
        )
      query <-
        list_tables_sql(
          conn = conn,
          where_schema = where_schema,
          order_by = "cl.relkind, cl.relname"
        )
      query <- paste0(
        "SELECT nspname AS schema, relname AS table FROM ( \n",
        query,
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
})
