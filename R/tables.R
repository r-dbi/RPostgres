#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn a \code{\linkS4class{PqConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characaters, not
#'   just any valid bare table name.
#' @param value A data.frame to write to the database.
#' @inheritParams SQL::rownamesToColumn
#' @inheritParams SQL::sqlTableCreate
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is \code{FALSE}.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS. Its default is \code{FALSE}.
#' @param field.types character vector of named SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
#' @examples
#' con <- dbConnect(RPostgres::Postgres())
#' dbListTables(con)
#' dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' dbReadTable(con, "mtcars")
#'
#' dbListTables(con)
#' dbExistsTable(con, "mtcars")
#'
#' # A zero row data frame just creates a table definition.
#' dbWriteTable(con, "mtcars2", mtcars[0, ], temporary = TRUE)
#' dbReadTable(con, "mtcars2")
#'
#' dbDisconnect(con)
#' @name postgres-tables
NULL

#' @export
#' @rdname postgres-tables
setMethod("dbWriteTable", c("PqConnection", "character", "data.frame"),
  function(conn, name, value, row.names = NA, overwrite = FALSE, append = FALSE,
    field.types = NULL, temporary = FALSE) {

    if (overwrite && append)
      stop("overwrite and append cannot both be TRUE", call. = FALSE)

    dbBegin(conn)
    on.exit(dbRollback(conn))

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    if (!found || overwrite) {
      sql <- SQL::sqlTableCreate(conn, name, value, row.names = row.names,
        temporary = temporary)
      dbGetQuery(conn, sql)
    }

    if (nrow(value) > 0) {
      sql <- SQL::sqlTableInsertInto(conn, name, value, row.names = row.names)
      dbGetQuery(conn, sql)
    }

    on.exit(NULL)
    dbCommit(conn)
    TRUE
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbReadTable", c("PqConnection", "character"),
  function(conn, name, row.names = NA) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("SELECT * FROM ", name), row.names = row.names)
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbListTables", "PqConnection", function(conn) {
  dbGetQuery(conn, paste0(
    "SELECT tablename FROM pg_tables WHERE schemaname !='information_schema'",
    " AND schemaname !='pg_catalog'")
  )[[1]]
})

#' @export
#' @rdname postgres-tables
setMethod("dbExistsTable", "PqConnection", function(conn, name) {
  name %in% dbListTables(conn)
})

#' @export
#' @rdname postgres-tables
setMethod("dbRemoveTable", c("PqConnection", "character"),
  function(conn, name) {
    name <- dbQuoteIdentifier(conn, name)
    dbGetQuery(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  }
)
