#' Convenience functions for reading/writing DBMS tables
#'
#' @description [dbWriteTable()] executes several SQL statements that
#' create/overwrite a table and fill it with values.
#' \pkg{RPostgres} does not use parameterised queries to insert rows because
#' benchmarks revealed that this was considerably slower than using a single
#' SQL string.
#'
#' @section Schemas, catalogs, tablespaces:
#' Pass an identifier created with [Id()] as the `name` argument
#' to specify the schema or catalog, e.g.
#' `name = Id(catalog = "my_catalog", schema = "my_schema", table = "my_table")` .
#' To specify the tablespace, use
#' `dbExecute(conn, "SET default_tablespace TO my_tablespace")`
#' before creating the table.
#'
#' @param conn a [PqConnection-class] object, produced by
#'   [DBI::dbConnect()]
#' @param name a character string specifying a table name. Names will be
#'   automatically quoted so you can use any sequence of characters, not
#'   just any valid bare table name.
#'   Alternatively, pass a name quoted with [dbQuoteIdentifier()],
#'   an [Id()] object, or a string escaped with [SQL()].
#' @param value A data.frame to write to the database.
#' @inheritParams DBI::sqlCreateTable
#' @param overwrite a logical specifying whether to overwrite an existing table
#'   or not. Its default is `FALSE`.
#' @param append a logical specifying whether to append to an existing table
#'   in the DBMS. Its default is `FALSE`.
#' @param field.types character vector of named SQL field types where
#'   the names are the names of new table's columns.
#'   If missing, types are inferred with [DBI::dbDataType()]).
#'   The types can only be specified with `append = FALSE`.
#' @param copy If `TRUE`, serializes the data frame to a single string
#'   and uses `COPY name FROM stdin`. This is fast, but not supported by
#'   all postgres servers (e.g. Amazon's Redshift). If `FALSE`, generates
#'   a single SQL string. This is slower, but always supported.
#'   The default maps to `TRUE` on connections established via [Postgres()]
#'   and to `FALSE` on connections established via [Redshift()].
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

sql_data_copy <- function(value, conn, row.names = FALSE) {
  # C code takes care of atomic vectors, just need to coerce objects
  is_object <- vlapply(value, is.object)
  is_difftime <- vlapply(value, function(c) inherits(c, "difftime"))
  is_blob <- vlapply(value, is.list)
  is_character <- vlapply(value, is.character)

  value <- fix_posixt(value, conn@timezone)

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

db_append_table <- function(conn, name, value, copy, warn) {
  value <- factor_to_string(value, warn = warn)

  if (is.null(copy)) {
    copy <- !is(conn, "RedshiftConnection")
  }

  if (copy) {
    value <- sql_data_copy(value, conn, row.names = FALSE)

    fields <- dbQuoteIdentifier(conn, names(value))
    sql <- paste0(
      "COPY ", dbQuoteIdentifier(conn, name),
      " (", paste(fields, collapse = ", "), ")",
      " FROM STDIN"
    )
    connection_copy_data(conn@ptr, sql, value)
  } else {
    sql <- sqlAppendTable(conn, name, value, row.names = FALSE)
    dbExecute(conn, sql)
  }

  nrow(value)
}

exists_table <- function(conn, id) {
  name <- id@name

  query <- paste0(
    "SELECT COUNT(*) FROM ",
    find_table(conn, name)
  )

  dbGetQuery(conn, query)[[1]] >= 1
}

find_table <- function(conn, id, inf_table = "tables", only_first = FALSE) {
  is_redshift <- is(conn, "RedshiftConnection")

  if ("schema" %in% names(id)) {
    query <- paste0(
      "(SELECT 1 AS nr, ",
      dbQuoteString(conn, id[["schema"]]), "::varchar",
      " AS table_schema) t"
    )
  } else if (is_redshift) {
    # A variant of the Postgres version that uses CTEs and generate_series()
    # instead of generate_subscripts(), the latter is not supported on Redshift
    query <- paste0(
      "(WITH ",
      " n_schemas AS (",
      "  SELECT max(regexp_count(setting, '[,]')) + 2 AS max_num ",
      "  FROM pg_settings WHERE name='search_path'",
      " ),",
      " tt AS (",
      "  SELECT generate_series(1, max_num) AS nr, current_schemas(true)::text[] ",
      "  FROM n_schemas",
      " )",
      " SELECT nr, current_schemas[nr] AS table_schema FROM tt WHERE current_schemas[nr] <> 'pg_catalog'",
      ") ttt"
    )
    only_first <- FALSE
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

find_temp_schema <- function(conn, fail_if_missing = TRUE) {
  if (!is.na(connection_get_temp_schema(conn@ptr)))
    return(connection_get_temp_schema(conn@ptr))
  if (is(conn, "RedshiftConnection")) {
    temp_schema <- dbGetQuery(
      conn,
      paste0(
        "SELECT current_schemas[1] as schema ",
        "FROM (SELECT current_schemas(true)) ",
        "WHERE current_schemas[1] LIKE 'pg_temp_%'"
      )
    )

    if (nrow(temp_schema) == 1 && is.character(temp_schema[[1]])) {
      connection_set_temp_schema(conn@ptr, temp_schema[[1]])
      return(connection_get_temp_schema(conn@ptr))
    } else {
      # Temporary schema do not exist yet.
      if (fail_if_missing) stopc("temporary schema does not exist")
      return(NULL)
    }
  } else {
    connection_set_temp_schema(conn@ptr, "pg_temp")
    return(connection_get_temp_schema(conn@ptr))
  }
}

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
