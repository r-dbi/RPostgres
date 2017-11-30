vlapply <- function(X, FUN, ..., USE.NAMES = TRUE) {
  vapply(X = X, FUN = FUN, FUN.VALUE = logical(1L), ..., USE.NAMES = USE.NAMES)
}

viapply <- function(X, FUN, ..., USE.NAMES = TRUE) {
  vapply(X = X, FUN = FUN, FUN.VALUE = integer(1L), ..., USE.NAMES = USE.NAMES)
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

is_whole_number_vector <- function(x) {
  if (!is.numeric(x)) return(FALSE)
  is_value <- which(!is.na(x))
  isTRUE(all.equal(x[is_value] - trunc(x[is_value]), rep_len(0, length(is_value))))
}
