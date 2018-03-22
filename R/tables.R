#' Convenience functions for reading/writing DBMS tables
#'
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characters, not
#'   just any valid bare table name.
#' @param value A data.frame to write to the database.
#' @inheritParams DBI::sqlCreateTable
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is `FALSE`.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS. Its default is `FALSE`.
#' @param field.types character vector of named SQL field types where
#'   the names are the names of new table's columns. If missing, types inferred
#'   with [DBI::dbDataType()]).
#' @param copy If `TRUE`, serializes the data frame to a single string
#'   and uses `COPY name FROM stdin`. This is fast, but not supported by
#'   all postgres servers (e.g. Amazon's redshift). If `FALSE`, generates
#'   a single SQL string. This is slower, but always supported.
#'
#'   RPostgres does not use parameterised queries to insert rows because
#'   benchmarks revealed that this was considerably slower than using a single
#'   SQL string.
#' @examples
#' # For running the examples on systems without PostgreSQL connection:
#' run <- postgresHasDefault()
#'
#' library(DBI)
#' if (run) con <- dbConnect(RPostgres::Postgres())
#' if (run) dbListTables(con)
#' if (run) dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
#' if (run) dbReadTable(con, "mtcars")
#'
#' if (run) dbListTables(con)
#' if (run) dbExistsTable(con, "mtcars")
#'
#' # A zero row data frame just creates a table definition.
#' if (run) dbWriteTable(con, "mtcars2", mtcars[0, ], temporary = TRUE)
#' if (run) dbReadTable(con, "mtcars2")
#'
#' if (run) dbDisconnect(con)
#' @name postgres-tables
NULL

#' @export
#' @rdname postgres-tables
setMethod("dbWriteTable", c("PqConnection", "character", "data.frame"),
  function(conn, name, value, ..., row.names = FALSE, overwrite = FALSE, append = FALSE,
           field.types = NULL, temporary = FALSE, copy = TRUE) {

    if (is.null(row.names)) row.names <- FALSE
    if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L)  {
      stopc("`row.names` must be a logical scalar or a string")
    }
    if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite))  {
      stopc("`overwrite` must be a logical scalar")
    }
    if (!is.logical(append) || length(append) != 1L || is.na(append))  {
      stopc("`append` must be a logical scalar")
    }
    if (!is.logical(temporary) || length(temporary) != 1L)  {
      stopc("`temporary` must be a logical scalar")
    }
    if (overwrite && append) {
      stopc("overwrite and append cannot both be TRUE")
    }
    if (append && !is.null(field.types)) {
      stopc("Cannot specify field.types with append = TRUE")
    }

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    if (!found || overwrite) {
      if (!is.null(field.types)) {
        if (is.null(names(field.types)))
          types <- structure(field.types, .Names = colnames(value))
        else
          types <- field.types
      } else {
        types <- value
      }
      sql <- sqlCreateTable(conn, name, if (is.null(field.types)) value else types,
        row.names = row.names, temporary = temporary)
      dbExecute(conn, sql)
    }

    if (nrow(value) > 0) {
      value <- sqlData(conn, value, row.names = row.names, copy = copy)
      if (!copy) {
        sql <- sqlAppendTable(conn, name, value)
        dbExecute(conn, sql)
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

    invisible(TRUE)
  }
)


#' @export
#' @inheritParams DBI::sqlRownamesToColumn
#' @rdname postgres-tables
setMethod("sqlData", "PqConnection", function(con, value, row.names = FALSE, copy = TRUE) {
  if (is.null(row.names)) row.names <- FALSE
  value <- sqlRownamesToColumn(value, row.names)

  # C code takes care of atomic vectors, just need to coerce objects
  is_object <- vlapply(value, is.object)
  is_posix <- vlapply(value, function(c) inherits(c, "POSIXt"))
  is_difftime <- vlapply(value, function(c) inherits(c, "difftime"))
  is_blob <- vlapply(value, function(c) is.list(c))
  is_whole_number <- vlapply(value, is_whole_number_vector)

  withr::with_options(
    list(digits.secs = 6),
    value[is_posix] <- lapply(value[is_posix], function(col) format_keep_na(col, usetz = T))
  )
  value[is_difftime] <- lapply(value[is_difftime], function(col) format_keep_na(hms::as.hms(col)))
  value[is_blob] <- lapply(
    value[is_blob],
    function(col) {
      vapply(
        col,
        function(x) {
          if (is.null(x)) NA_character_
          else paste0("\\x", paste(format(x), collapse = ""))
        },
        character(1)
      )
    }
  )

  value[is_whole_number] <- lapply(
    value[is_whole_number],
    function(x) {
      is_value <- which(!is.na(x))
      x[is_value] <- format(x[is_value], scientific = FALSE, na.encode = FALSE)
      x
    }
  )

  value[is_object] <- lapply(value[is_object], as.character)
  value
})

format_keep_na <- function(x, ...) {
  is_na <- is.na(x)
  ret <- format(x, ...)
  ret[is_na] <- NA
  ret
}


#' @export
#' @param check.names If `TRUE`, the default, column names will be
#'   converted to valid R identifiers.
#' @rdname postgres-tables
setMethod("dbReadTable", c("PqConnection", "character"),
  function(conn, name, ..., check.names = TRUE, row.names = FALSE) {

    if (is.null(row.names)) row.names <- FALSE
    if ((!is.logical(row.names) && !is.character(row.names)) || length(row.names) != 1L)  {
      stopc("`row.names` must be a logical scalar or a string")
    }

    if (!is.logical(check.names) || length(check.names) != 1L)  {
      stopc("`check.names` must be a logical scalar")
    }

    name <- dbQuoteIdentifier(conn, name)
    out <- dbGetQuery(conn, paste("SELECT * FROM ", name), row.names = row.names)

    if (check.names) {
      names(out) <- make.names(names(out), unique = TRUE)
    }

    out
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbListTables", "PqConnection", function(conn, ...) {
  query <- paste0(
    "SELECT table_name FROM INFORMATION_SCHEMA.tables ",
    "WHERE ",
    "(table_schema = ANY(current_schemas(false)) OR table_type = 'LOCAL TEMPORARY')"
  )
  dbGetQuery(conn, query)[[1]]
})

#' @export
#' @rdname postgres-tables
setMethod("dbExistsTable", c("PqConnection", "character"), function(conn, name, ...) {
  stopifnot(length(name) == 1L)
  name <- dbQuoteIdentifier(conn, name)

  # Convert to identifier
  id <- dbUnquoteIdentifier(conn, name)[[1]]@name
  table <- dbQuoteString(conn, id[["table"]])

  query <- paste0(
    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.tables WHERE table_name = ",
    table
  )

  if ("schema" %in% names(id)) {
    query <- paste0(
      query,
      "AND ",
      "table_schema = ",
      dbQuoteString(conn, id[["schema"]])
    )
  } else {
    query <- paste0(
      query,
      "AND ",
      "(table_schema = ANY(current_schemas(false)) OR table_type = 'LOCAL TEMPORARY')"
    )
  }

  dbGetQuery(conn, query)[[1]] >= 1
})

#' @export
#' @rdname postgres-tables
setMethod("dbRemoveTable", c("PqConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteIdentifier(conn, name)
    dbExecute(conn, paste("DROP TABLE ", name))
    invisible(TRUE)
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbListFields", c("PqConnection", "character"),
  function(conn, name, ...) {
    name <- dbQuoteString(conn, name)
    query <- paste0("SELECT column_name FROM information_schema.columns WHERE table_name = ", name)
    dbGetQuery(conn, query)[[1]]
  }
)

#' @export
#' @inheritParams DBI::dbListObjects
#' @rdname postgres-tables
setMethod("dbListObjects", c("PqConnection", "ANY"), function(conn, prefix = NULL, ...) {
  query <- NULL
  if (is.null(prefix)) {
    query <- paste0(
      "SELECT NULL AS schema, table_name AS table FROM INFORMATION_SCHEMA.tables\n",
      "WHERE ",
      "(table_schema = ANY(current_schemas(false)) OR table_type = 'LOCAL TEMPORARY')\n",
      "UNION ALL\n",
      "SELECT DISTINCT table_schema AS schema, NULL AS table FROM INFORMATION_SCHEMA.tables"
    )
  } else {
    unquoted <- dbUnquoteIdentifier(conn, prefix)
    is_prefix <- vlapply(unquoted, function(x) { "schema" %in% names(x@name) && !("table" %in% names(x@name)) })
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
  tables <- Map(res$schema, res$table, f = as_table)

  ret <- data.frame(
    table = I(unname(tables)),
    is_prefix = is_prefix,
    stringsAsFactors = FALSE
  )
  ret
})
