# show()
#' @rdname PqConnection-class
#' @usage NULL
show_PqConnection <- function(object) {
  info <- dbGetInfo(object)

  if (info$host == "") {
    host <- "socket"
  } else {
    host <- paste0(info$host, ":", info$port)
  }

  cat("<PqConnection> ", info$dbname, "@", host, "\n", sep = "")
}

#' @rdname PqConnection-class
#' @export
setMethod("show", "PqConnection", show_PqConnection)
