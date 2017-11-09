vlapply <- function(X, FUN, ..., USE.NAMES = TRUE) {
  vapply(X = X, FUN = FUN, FUN.VALUE = logical(1L), ..., USE.NAMES = USE.NAMES)
}

vcapply <- function(X, FUN, ..., USE.NAMES = TRUE) {
  vapply(X = X, FUN = FUN, FUN.VALUE = character(1L), ..., USE.NAMES = USE.NAMES)
}

stopc <- function(...) {
  stop(..., call. = FALSE, domain = NA)
}

warningc <- function(...) {
  warning(..., call. = FALSE, domain = NA)
}
