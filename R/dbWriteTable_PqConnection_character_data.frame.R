#' @rdname postgres-tables
#' @usage NULL
dbWriteTable_PqConnection_character_data.frame <- function(
  conn,
  name,
  value,
  ...,
  row.names = FALSE,
  overwrite = FALSE,
  append = FALSE,
  field.types = NULL,
  temporary = FALSE,
  copy = NULL
) {
  if (is.null(row.names)) {
    row.names <- FALSE
  }
  if (
    (!is.logical(row.names) && !is.character(row.names)) ||
      length(row.names) != 1L
  ) {
    stopc("`row.names` must be a logical scalar or a string")
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stopc("`overwrite` must be a logical scalar")
  }
  if (!is.logical(append) || length(append) != 1L || is.na(append)) {
    stopc("`append` must be a logical scalar")
  }
  if (!is.logical(temporary) || length(temporary) != 1L) {
    stopc("`temporary` must be a logical scalar")
  }
  if (overwrite && append) {
    stopc("overwrite and append cannot both be TRUE")
  }
  if (
    !is.null(field.types) &&
      !(is.character(field.types) &&
        !is.null(names(field.types)) &&
        !anyDuplicated(names(field.types)))
  ) {
    stopc(
      "`field.types` must be a named character vector with unique names, or NULL"
    )
  }
  if (append && !is.null(field.types)) {
    stopc("Cannot specify `field.types` with `append = TRUE`")
  }

  need_transaction <- !connection_is_transacting(conn@ptr)
  if (need_transaction) {
    dbBegin(conn)
  }

  if (!is(conn, "RedshiftConnection")) {
    dbBegin(conn, name = "dbWriteTable")
    # This is executed first, the `after` argument requires quite recent R
    on.exit({
      dbRollback(conn, name = "dbWriteTable")
    })
  }

  if (need_transaction) {
    on.exit({
      dbRollback(conn)
    })
  }

  if (overwrite) {
    suppressMessages(dbRemoveTable(
      conn,
      name,
      temporary = temporary,
      fail_if_missing = FALSE
    ))
    found <- FALSE
  } else {
    found <- dbExistsTable(conn, name)
    if (found && !append) {
      stopc(
        "Table ",
        name,
        " exists in database, and both overwrite and append are FALSE"
      )
    }
  }

  value <- sqlRownamesToColumn(value, row.names)

  if (!found) {
    if (is.null(field.types)) {
      combined_field_types <- lapply(value, dbDataType, dbObj = conn)
    } else {
      combined_field_types <- rep("", length(value))
      names(combined_field_types) <- names(value)
      field_types_idx <- match(names(field.types), names(combined_field_types))
      stopifnot(!any(is.na(field_types_idx)))
      combined_field_types[field_types_idx] <- field.types
      values_idx <- setdiff(seq_along(value), field_types_idx)
      combined_field_types[values_idx] <- lapply(
        value[values_idx],
        dbDataType,
        dbObj = conn
      )
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

  if (!is(conn, "RedshiftConnection")) {
    dbCommit(conn, name = "dbWriteTable")
  }
  if (need_transaction) {
    dbCommit(conn)
  }
  on.exit(NULL)

  invisible(TRUE)
}

#' @rdname postgres-tables
#' @export
setMethod(
  "dbWriteTable",
  c("PqConnection", "character", "data.frame"),
  dbWriteTable_PqConnection_character_data.frame
)
