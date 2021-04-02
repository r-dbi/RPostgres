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
  major_server_version <- dbGetInfo(conn)$db.version %/% 10000

  query <- paste0(
    # pg_class docs: https://www.postgresql.org/docs/current/catalog-pg-class.html
    "SELECT cl.relname AS name FROM pg_class AS cl ",
    "JOIN pg_namespace AS n ON cl.relnamespace = n.oid ",
    "WHERE (n.nspname = ANY (current_schemas(true))) ",
    "AND (n.nspname <> 'pg_catalog') "
  )

  if (major_server_version >= 10) {
    # relkind = 'p' and relispartition only supported from v10 onwards
    query <- paste0(
      query,
      # r = ordinary table, v = view, m = materialized view, f = foreign table, p = partitioned table
      "AND (cl.relkind IN ('r', 'v', 'm', 'f', 'p')) ",
      "AND NOT cl.relispartition "
    )
  } else {
    query <- paste0(
      query,
      "AND (cl.relkind IN ('r', 'v', 'm', 'f')) "
    )
  }

  query <- paste0(
    query,
    "ORDER BY name"
  )

  dbGetQuery(conn, query)[[1]]
})

