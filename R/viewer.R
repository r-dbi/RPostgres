# nocov start

#' connection display name
#' @noRd
pq_host_name <- function(connection) {
  info <- dbGetInfo(connection)
  paste(collapse = ":", info$host, info$port)
}

#' connection display name
#' @noRd
pq_display_name <- function(connection) {
  info <- dbGetInfo(connection)
  server_name <- paste(collapse = "@", info$username, info$host)
  display_name <- paste(collapse = " - ", info$dbname, server_name)
  display_name
}

#' connection icon
#' @noRd
pq_connection_icon <- function(connection) {
  switch(
    class(connection)[1],
    "PqConnection" = system.file("icons/elephant.png", package = "RPostgres"),
    "RedshiftConnection" = system.file("icons/redshift.png", package = "RPostgres")
  )
}

#' @noRd
pq_list_object_types <- function(connection) {
  obj_types <- list(table = list(contains = "data"))
  obj_types <- list(schema = list(contains = obj_types))
  obj_types
}

#' @noRd
pq_list_objects <- function(connection, schema = NULL, name = NULL, type = NULL, ...) {
  # if no schema was supplied but this database has schema, return a list of
  # schema
  if (is.null(schema)) {
    schemas <- dbGetQuery(conn, "SELECT schema_name FROM information_schema.schemata;")$schema_name
    if (length(schemas) > 0) {
      return(
        data.frame(
          name = schemas,
          type = rep("schema", times = length(schemas)),
          stringsAsFactors = FALSE
        ))
    }
  }

  sql_view <- paste("
    select table_schema,
           table_name,
           'view' as table_type
    from information_schema.views
    where table_schema not in ('information_schema', 'pg_catalog')
    ",
    if (!is.null(schema)) {
      sprintf("and table_schema = '%s'", schema)
    } else {""},
    if (!is.null(name)) {
      sprintf("and table_name = '%s'", name)
    } else {""})

  sql_table <- paste("
    select schemaname as table_schema,
           tablename as table_name,
           'table' as table_type
    from pg_catalog.pg_tables
    where 1=1
    ",
    if (!is.null(schema)) {
      sprintf("and schemaname = '%s'", schema)
    },
    if (!is.null(name)) {
      sprintf("and tablename = '%s'", name)
    })

  sql <- sprintf("%s union all %s;", sql_table, sql_view)

  objs <- dbGetQuery(connection, sql)

  data.frame(
    name = objs[["table_name"]],
    type = objs[["table_type"]],
    stringsAsFactors = FALSE
  )
}

#' @noRd
pq_list_columns <- function(connection, schema = NULL, table = NULL, ...) {
  sql <- sprintf("
  select column_name,
         data_type
  from information_schema.columns
  where table_schema not in ('information_schema', 'pg_catalog')
    and table_schema = '%s'
    and table_name = '%s'
  order by table_schema,
           table_name,
           ordinal_position;
  ", schema, table)
  cols <- dbGetQuery(connection, sql)
  data.frame(
    name = cols[["column_name"]],
    type = cols[["data_type"]],
    stringsAsFactors = FALSE)
}

#' @noRd
pq_preview_object <- function(connection, rowLimit, schema = NULL, table = NULL, ...) {
  sql <- sprintf("select * from %s.%s limit %s", schema, table, rowLimit)
  dbGetQuery(connection, sql)
}

#' @noRd
on_connection_closed <- function(connection) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  type <- class(connection)[1]
  host <- pq_host_name(connection)
  observer$connectionClosed(type, host)
}

#' @noRd
on_connection_updated <- function(connection, hint) {
  # make sure we have an observer
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  type <- class(connection)[1]
  host <- pq_host_name(connection)
  observer$connectionUpdated(type, host, hint = hint)
}

#' @noRd
on_connection_opened <- function(connection, code) {

  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  observer$connectionOpened(
    # connection type
    type = class(connection)[1],

    # name displayed in connection pane
    displayName = pq_display_name(connection),

    # host key
    host = pq_host_name(connection),

    # icon for connection
    icon = pq_connection_icon(connection),

    # connection code
    connectCode = code,

    # disconnection code
    disconnect = function() {
      dbDisconnect(connection)
    },

    listObjectTypes = function() {
      pq_list_object_types(connection)
    },

    # table enumeration code
    listObjects = function(...) {
      pq_list_objects(connection, ...)
    },

    # column enumeration code
    listColumns = function(...) {
      pq_list_columns(connection, ...)
    },

    # table preview code
    previewObject = function(rowLimit, ...) {
      pq_preview_object(connection, rowLimit, ...)
    },

    # no actions

    # raw connection object
    connectionObject = connection

  )
}

# nocov end
