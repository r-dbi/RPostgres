#' PostgreSQL results.
#'
#' @keywords internal
#' @include connection.R
#' @export
setClass("PqResult",
  contains = "DBIResult",
  slots = list(
    conn = "PqConnection",
    ptr = "externalptr",
    sql = "character"
  )
)

#' @rdname PqResult-class
#' @export
setMethod("dbGetStatement", "PqResult", function(res, ...) {
  if (!dbIsValid(res)) {
    stop("Invalid result set.", call. = FALSE)
  }
  res@sql
})

#' @rdname PqResult-class
#' @export
setMethod("dbIsValid", "PqResult", function(dbObj, ...) {
  result_active(dbObj@ptr)
})

#' @rdname PqResult-class
#' @export
setMethod("dbGetRowCount", "PqResult", function(res, ...) {
  result_rows_fetched(res@ptr)
})

#' @rdname PqResult-class
#' @export
setMethod("dbGetRowsAffected", "PqResult", function(res, ...) {
  result_rows_affected(res@ptr)
})

#' @rdname PqResult-class
#' @export
setMethod("dbColumnInfo", "PqResult", function(res, ...) {
  result_column_info(res@ptr)
})

#' Execute a SQL statement on a database connection
#'
#' To retrieve results a chunk at a time, use \code{dbSendQuery},
#' \code{dbFetch}, then \code{ClearResult}. Alternatively, if you want all the
#' results (and they'll fit in memory) use \code{dbGetQuery} which sends,
#' fetches and clears for you.
#'
#' @param conn A \code{\linkS4class{PqConnection}} created by \code{dbConnect}.
#' @param statement An SQL string to execture
#' @param params A list of query parameters to be substituted into
#'   a parameterised query. Query parameters are sent as strings, and the
#'   correct type is imputed by PostgreSQL. If this fails, you can manually
#'   cast the parameter with e.g. \code{"$1::bigint"}.
#' @param ... Another arguments needed for compatibility with generic (
#'   currently ignored).
#' @examples
#' library(DBI)
#' db <- dbConnect(RPostgres::Postgres())
#' dbWriteTable(db, "usarrests", datasets::USArrests, temporary = TRUE)
#'
#' # Run query to get results as dataframe
#' dbGetQuery(db, "SELECT * FROM usarrests LIMIT 3")
#'
#' # Send query to pull requests in batches
#' res <- dbSendQuery(db, "SELECT * FROM usarrests")
#' dbFetch(res, n = 2)
#' dbFetch(res, n = 2)
#' dbHasCompleted(res)
#' dbClearResult(res)
#'
#' dbRemoveTable(db, "usarrests")
#'
#' dbDisconnect(db)
#' @name postgres-query
NULL

#' @export
#' @rdname postgres-query
setMethod("dbSendQuery", c("PqConnection", "character"), function(conn, statement, params = NULL, ...) {
  statement <- enc2utf8(statement)

  rs <- new("PqResult",
    conn = conn,
    ptr = result_create(conn@ptr, statement),
    sql = statement)

  if (!is.null(params)) {
    dbBind(rs, params)
  }

  rs
})

#' @param res Code a \linkS4class{PqResult} produced by
#'   \code{\link[DBI]{dbSendQuery}}.
#' @param n Number of rows to return. If less than zero returns all rows.
#' @inheritParams DBI::sqlRownamesToColumn
#' @export
#' @rdname postgres-query
setMethod("dbFetch", "PqResult", function(res, n = -1, ..., row.names = FALSE) {
  if (length(n) != 1) stopc("n must be scalar")
  if (n < -1) stopc("n must be nonnegative or -1")
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stopc("n must be a whole number")
  sqlColumnToRownames(result_fetch(res@ptr, n = n), row.names)
})

#' @rdname postgres-query
#' @export
setMethod("dbBind", "PqResult", function(res, params, ...) {
  if (!is.null(names(params))) {
    stop("Named parameters not supported", call. = FALSE)
  }
  if (!is.list(params)) params <- as.list(params)
  params <- factor_to_string(params, warn = TRUE)
  params <- posixlt_to_posixct(params)
  params <- difftime_to_hms(params)
  params <- prepare_for_binding(params)
  result_bind_params(res@ptr, params)
  invisible(res)
})

factor_to_string <- function(value, warn = FALSE) {
  is_factor <- vlapply(value, is.factor)
  if (warn && any(is_factor)) {
    warning("Factors converted to character", call. = FALSE)
  }
  value[is_factor] <- lapply(value[is_factor], as.character)
  value
}

posixlt_to_posixct <- function(value) {
  is_posixlt <- vlapply(value, inherits, "POSIXlt")
  value[is_posixlt] <- lapply(value[is_posixlt], as.POSIXct)
  value
}

difftime_to_hms <- function(value) {
  is_difftime <- vlapply(value, inherits, "difftime")
  value[is_difftime] <- lapply(value[is_difftime], hms::as.hms)
  value
}

prepare_for_binding <- function(value) {
  is_list <- vlapply(value, is.list)
  value[!is_list] <- lapply(value[!is_list], as.character)
  value[!is_list] <- lapply(value[!is_list], enc2utf8)
  value[is_list] <- lapply(value[is_list], vcapply, function(x) {
    if (is.null(x)) NA_character_
    else if (is.raw(x)) {
      paste(sprintf("\\%.3o", as.integer(x)), collapse = "")
    } else {
      stop("Lists must contain raw vectors or NULL", call. = FALSE)
    }
  })
  value
}

#' @rdname postgres-query
#' @export
setMethod("dbHasCompleted", "PqResult", function(res, ...) {
  result_is_complete(res@ptr)
})

#' @rdname postgres-query
#' @export
setMethod("dbClearResult", "PqResult", function(res, ...) {
  if (!dbIsValid(res)) {
    warningc("Expired, result set already closed")
    return(invisible(TRUE))
  }
  result_release(res@ptr)
  invisible(TRUE)
})
