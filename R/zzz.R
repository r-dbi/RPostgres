.onLoad <- function(libname, pkgname) {
    options(digits.secs=6)
    invisible()
}

.onUnload <- function(libname) {
    options(digits.secs=NULL)
}
