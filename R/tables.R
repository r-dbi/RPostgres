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

list_tables <- function(conn, where_schema = NULL, where_table = NULL, order_by = NULL) {

  if (conn@system_catalogs) {
    query <- paste0(
      "SELECT table_schema, table_name \n",
      "FROM ( ", list_tables_from_system_catalog(), ") AS schema_tables \n",
      "WHERE TRUE \n"
    )
  } else {
    query <- paste0(
      # information_schema.table docs:
      # https://www.postgresql.org/docs/current/infoschema-tables.html
      "SELECT table_schema, table_name \n",
      "FROM information_schema.tables \n",
      "WHERE TRUE \n" # dummy clause to be able to add additional ones with `AND`
    )
  }

  if (is.null(where_schema)) {
    # `true` in `current_schemas(true)` is necessary to get temporary tables
    query <- paste0(
      query,
      "  AND (table_schema = ANY(current_schemas(true))) \n",
      "  AND (table_schema <> 'pg_catalog') \n"
    )
  } else {
    query <- paste0(query, "  AND ", where_schema)
  }

  if (!is.null(where_table)) query <- paste0(query, "  AND ", where_table)

  if (!is.null(order_by)) query <- paste0(query, "ORDER BY ", order_by)

  query
}

list_tables_from_system_catalog <- function() {
  # This imitates (parts of) information_schema.tables, but includes materialized views
  paste0(
    # pg_class vs. information_schema: https://stackoverflow.com/a/24089729
    # pg_class docs: https://www.postgresql.org/docs/current/catalog-pg-class.html
    "SELECT n.nspname AS table_schema, cl.relname AS table_name, \n",
    "    CASE
            WHEN (n.oid = pg_my_temp_schema()) THEN 'LOCAL TEMPORARY'
            WHEN (cl.relkind IN ('r', 'p')) THEN 'BASE TABLE'
            WHEN (cl.relkind = 'v') THEN 'VIEW'
            WHEN (cl.relkind = 'f') THEN 'FOREIGN'
            WHEN (cl.relkind = 'm') THEN 'MATVIEW'
            ELSE NULL
        END AS table_type \n",
    "FROM pg_class AS cl \n",
    "JOIN pg_namespace AS n ON cl.relnamespace = n.oid \n",
    # include: r = ordinary table, v = view, m = materialized view,
    #          f = foreign table, p = partitioned table
    "WHERE (cl.relkind IN ('r', 'v', 'm', 'f', 'p')) \n",
    # do not return individual table partitions
    "  AND NOT cl.relispartition \n",
    # do not return other people's temp schemas
    "  AND (NOT pg_is_other_temp_schema(n.oid)) \n",
    # Return only objects (relations) which the current user may access
    # https://www.postgresql.org/docs/current/functions-info.html
    "  AND (pg_has_role(cl.relowner, 'USAGE') \n",
    "    OR has_table_privilege(cl.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') \n",
    "    OR has_any_column_privilege(cl.oid, 'SELECT, INSERT, UPDATE, REFERENCES') \n",
    "  ) \n"
  )
}

exists_table <- function(conn, id) {
  name <- id@name
  stopifnot("table" %in% names(name))
  table_name <- dbQuoteString(conn, name[["table"]])
  where_table <- paste0("table_name = ", table_name, " \n")

  if ("schema" %in% names(name)) {
    schema_name <- dbQuoteString(conn, name[["schema"]])
    where_schema <- paste0("table_schema = ", schema_name, " \n")
  } else {
    where_schema <- NULL
  }
  query <- paste0(
    "SELECT EXISTS ( \n",
    list_tables(conn, where_schema = where_schema, where_table = where_table),
    ")"
  )
  dbGetQuery(conn, query)[[1]]
}

list_fields <- function(conn, id) {
  if (conn@system_catalogs) {
    list_fields_from_system_catalog(conn, id)
  } else {
    list_fields_from_info_schema(conn, id)
  }
}

list_fields_from_info_schema <- function(conn, id) {
  name <- id@name

  is_redshift <- is(conn, "RedshiftConnection")

  # get relevant schema
  if ("schema" %in% names(name)) {
    # either the user provides the schema
    query <- paste0(
      "(SELECT 1 AS nr, ",
      dbQuoteString(conn, name[["schema"]]), "::varchar",
      " AS table_schema) t"
    )

    # only_first not necessary,
    # as there cannot be multiple tables with the same name in a single schema
    only_first <- FALSE

  # or we have to look the table up in the schemas on the search path
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
    # Get `current_schemas()` in search_path order
    # so $user and temp tables take precedence over the public schema (by default)
    # https://www.postgresql.org/docs/current/ddl-schemas.html#DDL-SCHEMAS-PATH
    # https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-SEARCH-PATH
    # How to unnest `current_schemas(true)` array with element number (works since v9.4):
    # https://stackoverflow.com/a/8767450/2114932
    query <- paste0(
        "(",
        "SELECT * FROM unnest(current_schemas(true)) WITH ORDINALITY AS tbl(table_schema, nr) \n",
        "WHERE table_schema != 'pg_catalog'",
        ") schemas_on_path"
    )
    only_first <- TRUE
  }

  # join columns info
  table <- dbQuoteString(conn, name[["table"]])
  query <- paste0(
    query, " ",
    "INNER JOIN INFORMATION_SCHEMA.COLUMNS USING (table_schema) ",
    "WHERE table_name = ", table
  )

  if (only_first) {
    # we can only detect duplicate table names after we know in which schemas they are
    # https://stackoverflow.com/a/31814584/946850
    query <- paste0(
      "(SELECT *, rank() OVER (ORDER BY nr) AS rnr ",
      "FROM ", query,
      ") tttt WHERE rnr = 1"
    )
  }

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

list_fields_from_system_catalog <- function(conn, id) {
  if (exists_table(conn, id)) {
    # we know from exists_table() that id@name["table"] exists
    # and the user has access priviledges
    tname_str <- stats::na.omit(id@name[c("schema", "table")])
    tname_qstr <- dbQuoteString(conn, paste(tname_str, collapse = "."))
    # cast to `regclass` resolves the table name according to the current
    # `search_path` https://dba.stackexchange.com/a/75124
    query <-
      paste0(
        "SELECT attname \n",
        "FROM   pg_attribute \n",
        "WHERE  attrelid = ", tname_qstr, "::regclass \n",
        "  AND  attnum > 0 \n",
        "  AND  NOT attisdropped \n",
        "ORDER  BY attnum;"
      )
    dbGetQuery(conn, query)[[1]]
  } else {
    stop("Table ", dbQuoteIdentifier(conn, id), " not found.", call. = FALSE)
  }
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
