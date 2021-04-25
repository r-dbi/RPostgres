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
#' if (run) dbListTables(con)
#'
#' if (run) dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' if (run) dbListTables(con)
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
  query <- list_tables_sql(conn = conn)

  dbGetQuery(conn, query)[["relname"]]
})

list_tables_sql <- function(conn, where_schema = NULL) {
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

  query <- paste0(
    query,
    "ORDER BY cl.relkind, cl.relname"
  )

  query
}

