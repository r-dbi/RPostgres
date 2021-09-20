#' PostgreSQL results.
#'
#' @keywords internal
#' @include PqConnection.R
#' @export
setClass("PqResult",
  contains = "DBIResult",
  slots = list(
    conn = "PqConnection",
    ptr = "externalptr",
    sql = "character",
    bigint = "character"
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
  result_valid(dbObj@ptr)
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
  rci <- result_column_info(res@ptr)
  rci <- cbind(rci, .typname = type_lookup(rci[[".oid"]], res@conn), stringsAsFactors = FALSE)
  rci$name <- tidy_names(rci$name)
  rci
})

#' Execute a SQL statement on a database connection
#'
#' To retrieve results a chunk at a time, use `dbSendQuery()`,
#' `dbFetch()`, then `dbClearResult()`. Alternatively, if you want all the
#' results (and they'll fit in memory) use `dbGetQuery()` which sends,
#' fetches and clears for you.
#'
#' @param conn A [PqConnection-class] created by [dbConnect()].
#' @param statement An SQL string to execute.
#' @param params A list of query parameters to be substituted into
#'   a parameterised query. Query parameters are sent as strings, and the
#'   correct type is imputed by PostgreSQL. If this fails, you can manually
#'   cast the parameter with e.g. `"$1::bigint"`.
#' @param ... Other arguments needed for compatibility with generic (currently
#'   ignored).
#' @examplesIf postgresHasDefault()
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
#' @param immediate If `TRUE`, uses the `PGsendQuery()` API instead of `PGprepare()`.
#'   This allows to pass multiple statements and turns off the ability to pass parameters.
#' @rdname postgres-query
setMethod("dbSendQuery", c("PqConnection", "character"), function(conn, statement, params = NULL, ..., immediate = FALSE) {
  statement <- enc2utf8(statement)

  rs <- new("PqResult",
    conn = conn,
    ptr = result_create(conn@ptr, statement, immediate),
    sql = statement,
    bigint = conn@bigint
  )

  if (!is.null(params)) {
    dbBind(rs, params)
  }

  rs
})

#' @param res Code a [PqResult-class] produced by
#'   [DBI::dbSendQuery()].
#' @param n Number of rows to return. If less than zero returns all rows.
#' @inheritParams DBI::sqlRownamesToColumn
#' @export
#' @rdname postgres-query
setMethod("dbFetch", "PqResult", function(res, n = -1, ..., row.names = FALSE) {
  if (length(n) != 1) stopc("n must be scalar")
  if (n < -1) stopc("n must be nonnegative or -1")
  if (is.infinite(n)) n <- -1
  if (trunc(n) != n) stopc("n must be a whole number")
  ret <- sqlColumnToRownames(result_fetch(res@ptr, n = n), row.names)
  ret <- convert_bigint(ret, res@bigint)
  ret <- finalize_types(ret, res@conn)
  ret <- fix_timezone(ret, res@conn)
  set_tidy_names(ret)
})

convert_bigint <- function(df, bigint) {
  if (bigint == "integer64") return(df)
  is_int64 <- which(vlapply(df, inherits, "integer64"))
  if (length(is_int64) == 0) return(df)

  as_bigint <- switch(bigint,
    integer = as.integer,
    numeric = as.numeric,
    character = as.character
  )

  df[is_int64] <- suppressWarnings(lapply(df[is_int64], as_bigint))
  df
}

finalize_types <- function(ret, conn) {
  known <- attr(ret, "known")
  is_unknown <- which(!known)

  if (length(is_unknown) > 0) {
    oids <- attr(ret, "oids")
    typnames <- type_lookup(oids[is_unknown], conn)
    typname_classes <- paste0("pq_", typnames)
    ret[is_unknown] <- Map(set_class, ret[is_unknown], typname_classes)
  }

  attr(ret, "oids") <- NULL
  attr(ret, "known") <- NULL
  ret
}

fix_timezone <- function(ret, conn) {
  is_without_tz <- which(attr(ret, "without_tz"))
  if (length(is_without_tz) > 0) {
    ret[is_without_tz] <- lapply(ret[is_without_tz], function(x) {
      x <- lubridate::with_tz(x, "UTC")
      lubridate::force_tz(x, conn@timezone)
    })
  }

  is_datetime <- which(vapply(ret, inherits, "POSIXt", FUN.VALUE = logical(1)))
  if (length(is_datetime) > 0) {
    ret[is_datetime] <- lapply(ret[is_datetime], lubridate::with_tz, conn@timezone_out)
  }

  attr(ret, "without_tz") <- NULL

  ret
}

set_class <- function(x, subclass = NULL) {
  class(x) <- c(subclass)
  x
}

type_lookup <- function(x, conn) {
  typnames <- conn@typnames
  typnames$typname[match(x, typnames$oid)]
}

#' @rdname postgres-query
#' @export
setMethod("dbBind", "PqResult", function(res, params, ...) {
  if (!is.null(names(params))) {
    stopc("`params` must not be named.")
  }
  if (!is.list(params)) params <- as.list(params)

  params <- factor_to_string(params, warn = TRUE)
  params <- fix_posixt(params, res@conn@timezone)
  params <- difftime_to_hms(params)
  params <- fix_numeric(params)
  params <- prepare_for_binding(params)
  result_bind(res@ptr, params)
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

fix_posixt <- function(value, tz) {
  is_posixt <- vlapply(value, function(c) inherits(c, "POSIXt"))
  withr::with_options(
    list(digits.secs = 6),
    value[is_posixt] <- lapply(value[is_posixt], function(col) {
      tz_col <- lubridate::with_tz(col, tz)
      format_keep_na(tz_col, format = "%Y-%m-%dT%H:%M:%OS%z")
    })
  )
  value
}

difftime_to_hms <- function(value) {
  is_difftime <- vlapply(value, inherits, "difftime")
  # https://github.com/tidyverse/hms/issues/84
  value[is_difftime] <- lapply(value[is_difftime], function(x) {
    mode(x) <- "double"
    hms::as_hms(x)
  })
  value
}

fix_numeric <- function(value) {
  is_numeric <- vlapply(value, is.numeric)
  value[is_numeric] <- lapply(
    value[is_numeric],
    function(x) format_keep_na(x, digits = 17, decimal.mark = ".", scientific = FALSE, na.encode = FALSE, trim = TRUE)
  )
  value
}

prepare_for_binding <- function(value) {
  is_list <- vlapply(value, is.list)
  value[!is_list] <- lapply(value[!is_list], function(x) enc2utf8(as.character(x)))
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
  result_has_completed(res@ptr)
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
