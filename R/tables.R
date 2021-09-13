#' Convenience functions for reading/writing DBMS tables
#'
#' @description [dbWriteTable()] executes several SQL statements that
#' create/overwrite a table and fill it with values.
#' \pkg{RPostgres} does not use parameterised queries to insert rows because
#' benchmarks revealed that this was considerably slower than using a single
#' SQL string.
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
#'   all postgres servers (e.g. Amazon's Redshift). If `FALSE`, generates
#'   a single SQL string. This is slower, but always supported.
#'
#' @examplesIf postgresHasDefault()
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
    if (!is.null(field.types) && !(is.character(field.types) && !is.null(names(field.types)) && !anyDuplicated(names(field.types)))) {
      stopc("`field.types` must be a named character vector with unique names, or NULL")
    }
    if (append && !is.null(field.types)) {
      stopc("Cannot specify `field.types` with `append = TRUE`")
    }

    need_transaction <- !connection_is_transacting(conn@ptr)
    if (need_transaction) {
      dbBegin(conn)
      on.exit(dbRollback(conn))
    }

    found <- dbExistsTable(conn, name)
    if (found && !overwrite && !append) {
      stop("Table ", name, " exists in database, and both overwrite and",
        " append are FALSE", call. = FALSE)
    }
    if (found && overwrite) {
      dbRemoveTable(conn, name)
    }

    value <- sqlRownamesToColumn(value, row.names)

    if (!found || overwrite) {
      if (is.null(field.types)) {
        combined_field_types <- lapply(value, dbDataType, dbObj = conn)
      } else {
        combined_field_types <- rep("", length(value))
        names(combined_field_types) <- names(value)
        field_types_idx <- match(names(field.types), names(combined_field_types))
        stopifnot(!any(is.na(field_types_idx)))
        combined_field_types[field_types_idx] <- field.types
        values_idx <- setdiff(seq_along(value), field_types_idx)
        combined_field_types[values_idx] <- lapply(value[values_idx], dbDataType, dbObj = conn)
      }

      dbCreateTable(
        conn = conn,
        name = name,
        fields = combined_field_types,
        temporary = temporary
      )
    }

    if (nrow(value) > 0) {
      db_append_table(conn, name, value, copy, warn = FALSE)
    }

    if (need_transaction) {
      dbCommit(conn)
      on.exit(NULL)
    }

    invisible(TRUE)
  }
)


#' @export
#' @inheritParams DBI::sqlRownamesToColumn
#' @param ... Ignored.
#' @rdname postgres-tables
setMethod("sqlData", "PqConnection", function(con, value, row.names = FALSE, ...) {
  if (is.null(row.names)) row.names <- FALSE
  value <- sqlRownamesToColumn(value, row.names)

  value[] <- lapply(value, dbQuoteLiteral, conn = con)

  value
})

sql_data_copy <- function(value, row.names = FALSE) {
  # C code takes care of atomic vectors, just need to coerce objects
  is_object <- vlapply(value, is.object)
  is_difftime <- vlapply(value, function(c) inherits(c, "difftime"))
  is_blob <- vlapply(value, is.list)
  is_character <- vlapply(value, is.character)

  value <- fix_posixt(value)

  value[is_difftime] <- lapply(value[is_difftime], function(col) format_keep_na(hms::as_hms(col)))
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

  value <- fix_numeric(value)

  value[is_object] <- lapply(value[is_object], as.character)

  value[is_character] <- lapply(value[is_character], enc2utf8)
  value
}

format_keep_na <- function(x, ...) {
  is_na <- is.na(x)
  ret <- format(x, ...)
  ret[is_na] <- NA_character_
  ret
}

#' @description [dbAppendTable()] is overridden because \pkg{RPostgres}
#' uses placeholders of the form `$1`, `$2` etc. instead of `?`.
#' @rdname postgres-tables
#' @export
setMethod("dbAppendTable", c("PqConnection"),
  function(conn, name, value, copy = TRUE, ..., row.names = NULL) {
    stopifnot(is.null(row.names))
    stopifnot(is.data.frame(value))
    db_append_table(conn, name, value, copy = copy, warn = TRUE)
  }
)

db_append_table <- function(conn, name, value, copy, warn) {
  value <- factor_to_string(value, warn = warn)

  if (copy) {
    value <- sql_data_copy(value, row.names = FALSE)

    fields <- dbQuoteIdentifier(conn, names(value))
    sql <- paste0(
      "COPY ", dbQuoteIdentifier(conn, name),
      " (", paste(fields, collapse = ", "), ")",
      " FROM STDIN"
    )
    connection_copy_data(conn@ptr, sql, value)
  } else {
    value <- sqlData(conn, value, row.names = FALSE)

    sql <- sqlAppendTable(conn, name, value, row.names = FALSE)
    dbExecute(conn, sql)
  }

  nrow(value)
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
    "(table_schema = ANY(current_schemas(true))) AND (table_schema <> 'pg_catalog')"
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
  exists_table(conn, id)
})

#' @export
#' @rdname postgres-tables
setMethod("dbExistsTable", c("PqConnection", "Id"), function(conn, name, ...) {
  exists_table(conn, id = name@name)
})

exists_table <- function(conn, id) {
  query <- paste0(
    "SELECT COUNT(*) FROM ",
    find_table(conn, id)
  )

  dbGetQuery(conn, query)[[1]] >= 1
}

find_table <- function(conn, id, inf_table = "tables", only_first = FALSE) {
  if ("schema" %in% names(id)) {
    query <- paste0(
      "(SELECT 1 AS nr, ",
      dbQuoteString(conn, id[["schema"]]), "::varchar",
      " AS table_schema) t"
    )
  } else {
    # https://stackoverflow.com/a/8767450/946850
    query <- paste0(
      "(SELECT nr, schemas[nr] AS table_schema FROM ",
      "(SELECT *, generate_subscripts(schemas, 1) AS nr FROM ",
      "(SELECT current_schemas(true) AS schemas) ",
      "t) ",
      "tt WHERE schemas[nr] <> 'pg_catalog') ",
      "ttt"
    )
  }

  table <- dbQuoteString(conn, id[["table"]])
  query <- paste0(
    query, " ",
    "INNER JOIN INFORMATION_SCHEMA.", inf_table, " USING (table_schema) ",
    "WHERE table_name = ", table
  )

  if (only_first) {
    # https://stackoverflow.com/a/31814584/946850
    query <- paste0(
      "(SELECT *, rank() OVER (ORDER BY nr) AS rnr ",
      "FROM ", query,
      ") tttt WHERE rnr = 1"
    )
  }

  query
}

#' @export
#' @rdname postgres-tables
#' @param temporary If `TRUE`, only temporary tables are considered.
#' @param fail_if_missing If `FALSE`, `dbRemoveTable()` succeeds if the
#'   table doesn't exist.
setMethod("dbRemoveTable", c("PqConnection", "character"),
  function(conn, name, ..., temporary = FALSE, fail_if_missing = TRUE) {
    name <- dbQuoteIdentifier(conn, name)
    if (fail_if_missing) {
      extra <- ""
    } else {
      extra <- "IF EXISTS "
    }
    if (temporary) {
      extra <- paste0(extra, "pg_temp.")
    }
    dbExecute(conn, paste0("DROP TABLE ", extra, name))
    invisible(TRUE)
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbListFields", c("PqConnection", "character"),
  function(conn, name, ...) {
    quoted <- dbQuoteIdentifier(conn, name)
    id <- dbUnquoteIdentifier(conn, quoted)[[1]]@name

    list_fields(conn, id)
  }
)

#' @export
#' @rdname postgres-tables
setMethod("dbListFields", c("PqConnection", "Id"),
  function(conn, name, ...) {
    list_fields(conn, name@name)
  }
)

list_fields <- function(conn, id) {
  query <- find_table(conn, id, "columns", only_first = TRUE)
  query <- paste0(
    "SELECT column_name FROM ",
    query, " ",
    "ORDER BY ordinal_position"
  )
  fields <- dbGetQuery(conn, query)[[1]]
  if (length(fields) == 0) {
    stop("Table ", dbQuoteIdentifier(conn, id), " not found.", call. = FALSE)
  }
  fields
}

#' @export
#' @inheritParams DBI::dbListObjects
#' @rdname postgres-tables
setMethod("dbListObjects", c("PqConnection", "ANY"), function(conn, prefix = NULL, ...) {
  query <- NULL
  if (is.null(prefix)) {
    query <- paste0(
      "SELECT NULL AS schema, table_name AS table FROM INFORMATION_SCHEMA.tables\n",
      "WHERE ",
      "(table_schema = ANY(current_schemas(true))) AND (table_schema <> 'pg_catalog')\n",
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
  tables <- Map("", res$schema, res$table, f = as_table)

  ret <- data.frame(
    table = I(unname(tables)),
    is_prefix = is_prefix,
    stringsAsFactors = FALSE
  )
  ret
})
