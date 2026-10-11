# Restore the user-facing call on errors raised from C++.
#
# Server/result errors are signalled by signal_pq_error() (see
# R/signal_pq_error.R), which is invoked from C++ via
# cpp11::package("RPostgres")[["signal_pq_error"]]. cpp11 evaluates that helper
# in the global environment, so the condition is created detached from the R
# call stack and its `call` is empty. The longjmp from abort() is caught by
# cpp11's unwind protection and propagated back through the `.Call` boundary, so
# the condition object itself survives intact -- only the `call` is missing.
#
# rethrow() wraps the cpp11 entry points that can raise an RPostgres_error and
# re-attaches the call of whoever called the enclosing function (the DBI verb),
# preserving the condition's class and diagnostic fields. try_fetch() is used so
# the handler frames do not pollute the backtrace.
rethrow <- function(expr, call = rlang::caller_call()) {
  # S4 wraps methods that have extra formals (e.g. dbSendQuery()'s `immediate`)
  # in a `.local()` closure; skip it so the reported call is the DBI verb.
  if (is.call(call) && is.symbol(call[[1L]]) && call[[1L]] == ".local") {
    call <- rlang::caller_call(2L)
  }
  rlang::try_fetch(
    expr,
    RPostgres_error = function(cnd) {
      cnd$call <- call
      stop(cnd)
    }
  )
}
