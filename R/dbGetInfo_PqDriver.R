#' @rdname PqDriver-class
#' @usage NULL
dbGetInfo_PqDriver <- function(dbObj, ...) {
  client_version <- client_version()
  major <- client_version %/% 10000
  minor <- (client_version - major * 10000) %/% 100
  rev <- client_version - major * 10000 - minor * 100

  if (major >= 10) {
    client_version <- package_version(paste0(major, ".", rev))
  } else {
    client_version <- package_version(paste0(major, ".", minor, ".", rev))
  }

  list(
    driver.version = PACKAGE_VERSION,
    client.version = client_version
  )
}

#' @rdname PqDriver-class
#' @export
setMethod("dbGetInfo", "PqDriver", dbGetInfo_PqDriver)
