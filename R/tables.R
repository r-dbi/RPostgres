#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn a \code{\linkS4class{PqConnection}} object, produced by
#'   \code{\link[DBI]{dbConnect}}
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characaters, not
#'   just any valid bare table name.
#' @param value A data.frame to write to the database.
#' @inheritParams DBI::sqlCreateTable
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is \code{FALSE}.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS. Its default is \code{FALSE}.
#' @param field.types character vector of named SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with \code{\link[DBI]{dbDataType}}).
#' @param copy If \code{TRUE}, serializes the data frame to a single string
#'   and uses \code{COPY name FROM stdin}. This is fast, but not supported by
#'   all postgres servers (e.g. Amazon's redshift). If \code{FALSE}, generates
#'   a single SQL string. This is slower, but always supported.
#'
#'   RPostgres does not use parameterised queries to insert rows because
#'   benchmarks revealed that this was considerably slower than using a single
#'   SQL string.
#' @examples
#' library(DBI)
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
    field.types = NULL, temporary = FALSE, copy = TRUE) {

    if (overwrite && append)
      stop("overwrite and append cannot both be TRUE", call. = FALSE)

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    if (!found || overwrite) {
      if (!missing(field.types)) {
        types <- structure(field.types, .Names = colnames(value))
      } else {
        types <- value
      }
      sql <- sqlCreateTable(conn, name, types, row.names = row.names,
                            temporary = temporary)
      dbGetQuery(conn, sql)
    }

    if (nrow(value) > 0) {
      value <- sqlData(conn, value, row.names = row.names, copy = copy)
      if (!copy) {
        sql <- sqlAppendTable(conn, name, value)
        rs <- dbSendQuery(conn, sql)
      } else {
        fields <- dbQuoteIdentifier(conn, names(value))
        sql <- paste0(
          "COPY ", dbQuoteIdentifier(conn, name),
          " (", paste(fields, collapse = ", "), ")",
          " FROM STDIN"
        )
        connection_copy_data(conn@ptr, sql, value)
      }
    }

    TRUE
  }
)


#' @export
#' @inheritParams DBI::rownamesToColumn
#' @rdname postgres-tables
setMethod("sqlData", "PqConnection", function(con, value, row.names = NA, copy = TRUE) {
  value <- rownamesToColumn(value, row.names)

  # C code takes care of atomic vectors, just need to coerce objects
  is_object <- vapply(value, is.object, logical(1))
  value[is_object] <- lapply(value[is_object], as.character)

  value
})


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
