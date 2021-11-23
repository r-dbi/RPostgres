#' @include PqConnection.R
NULL

#' Quote postgres strings, identifiers, and literals
#'
#' If an object of class [Id] is used for `dbQuoteIdentifier()`, it needs
#' at most one `table` component and at most one `schema` component.
#'
#' @param conn A [PqConnection-class] created by `dbConnect()`
#' @param x A character vector to be quoted.
#' @param ... Other arguments needed for compatibility with generic (currently
#'   ignored).
#' @examplesIf postgresHasDefault()
#' library(DBI)
#' con <- dbConnect(RPostgres::Postgres())
#'
#' x <- c("a", "b c", "d'e", "\\f")
#' dbQuoteString(con, x)
#' dbQuoteIdentifier(con, x)
#' dbDisconnect(con)
#' @name quote
NULL

#' @export
#' @rdname quote
setMethod("dbQuoteString", c("PqConnection", "character"), function(conn, x, ...) {
  if (length(x) == 0) return(SQL(character()))
  if (is(conn, "RedshiftConnection")) {
    out <- paste0("'", gsub("(['\\\\])", "\\1\\1", enc2utf8(x)), "'")
    out[is.na(x)] <- "NULL"
  } else {
    out <- connection_quote_string(conn@ptr, enc2utf8(x))
  }
  SQL(out)
})

#' @export
#' @rdname quote
setMethod("dbQuoteString", c("PqConnection", "SQL"), function(conn, x, ...) {
  x
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "character"), function(conn, x, ...) {
  args <- list(...)
  if (anyNA(x)) {
    stop("Cannot pass NA to dbQuoteIdentifier()", call. = FALSE)
  }
  # Case where schema and table are character identifier
  if(isTRUE(conn@unquote_id) && length(x) == 1 && is.null(args$id) && grepl("\\.", x) &&
     !grepl("names\\((.*?)\\)", as.character(match.call())[[3]])) {
    id <- dbUnquoteIdentifier(conn, SQL(x))[[1]]
    return(dbQuoteIdentifier(conn, id, ...))
  }
  SQL(connection_quote_identifier(conn@ptr, x), names = names(x))
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "SQL"), function(conn, x, ...) {
  x
})

#' @export
#' @rdname quote
setMethod("dbQuoteIdentifier", c("PqConnection", "Id"), function(conn, x, ...) {
  stopifnot(all(names(x@name) %in% c("catalog", "schema", "table")))
  stopifnot(!anyDuplicated(names(x@name)))

  ret <- ""
  if ("catalog" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["catalog"]], id = "catalog"), ".")
  }
  if ("schema" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["schema"]], id = "schema"), ".")
  }
  if ("table" %in% names(x@name)) {
    ret <- paste0(ret, dbQuoteIdentifier(conn, x@name[["table"]], id = "table"))
  }
  SQL(ret)
})

#' @export
#' @rdname quote
setMethod("dbUnquoteIdentifier", c("PqConnection", "SQL"), function(conn, x, ...) {
  id_rx <- '(?:"((?:[^"]|"")+)"|([^". ]+))'

  rx <- paste0(
    "^",
    "(?:|(?:|", id_rx, "[.])",
    id_rx, "[.])",
    "(?:|", id_rx, ")",
    "$"
  )

  bad <- grep(rx, x, invert = TRUE)
  if (length(bad) > 0) {
    stop("Can't unquote ", x[bad[[1]]], call. = FALSE)
  }
  catalog <- gsub(rx, "\\1\\2", x)
  catalog <- gsub('""', '"', catalog)
  schema <- gsub(rx, "\\3\\4", x)
  schema <- gsub('""', '"', schema)
  table <- gsub(rx, "\\5\\6", x)
  table <- gsub('""', '"', table)

  ret <- Map(catalog, schema, table, f = as_table)
  names(ret) <- names(x)
  ret
})

as_table <- function(catalog, schema, table) {
  args <- c(catalog = catalog, schema = schema, table = table)
  # Also omits NA args
  args <- args[!is.na(args) & args != ""]
  do.call(Id, as.list(args))
}

#' @export
#' @importFrom blob blob
#' @rdname quote
setMethod("dbQuoteLiteral", "PqConnection", function(conn, x, ...) {
  if (is.factor(x)) {
    x <- as.character(x)
  }

  if (inherits(x, "Date")) {
    ret <- paste0("'", as.character(x), "'::date")
    ret[is.na(x)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (inherits(x, "POSIXt")) {
    ret <- paste0("'", as.character(lubridate::with_tz(x, conn@timezone)), "'::timestamp")
    ret[is.na(x)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (inherits(x, "difftime")) {
    ret <- paste0("'", as.character(hms::as_hms(x)), "'::interval")
    ret[is.na(x)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (is.logical(x)) {
    ret <- as.character(x)
    ret[is.na(ret)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (is.integer(x)) {
    ret <- paste0(as.character(x), "::int4")
    ret[is.na(x)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (is.numeric(x)) {
    ret <- paste0(as.character(x), "::float8")
    ret[is.na(x)] <- "NULL"
    SQL(ret, names = names(ret))
  } else if (is.list(x) || inherits(x, "blob")) {
    blob_data <- vcapply(
      x,
      function(x) {
        if (is.null(x)) "NULL"
        else if (is.raw(x)) paste0("E'\\\\x", paste(format(x), collapse = ""), "'")
        else {
          stopc("Lists must contain raw vectors or NULL")
        }
      }
    )
    SQL(blob_data, names = names(x))
  } else if (is.character(x)) {
    dbQuoteString(conn, x)
  } else {
    stopc("Can't convert value of class ", class(x)[[1]], " to SQL.", call. = FALSE)
  }
})
