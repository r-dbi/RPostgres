set_tidy_names <- function(x) {
  new_names <- tidy_names(names2(x))
  names(x) <- new_names
  x
}

names2 <- function(x) {
  name <- names(x)
  if (is.null(name)) {
    name <- rep("", length(x))
  }
  name
}

tidy_names <- function(name) {
  name[is.na(name)] <- ""
  append_pos(name)
}

append_pos <- function(name) {
  need_append_pos <- duplicated(name) | name == ""
  if (any(need_append_pos)) {
    rx <- "[.][.][1-9][0-9]*$"
    has_suffix <- grepl(rx, name)
    name[has_suffix] <- gsub(rx, "", name[has_suffix])
    need_append_pos <- need_append_pos | has_suffix
  }

  append_pos <- which(need_append_pos)
  name[append_pos] <- paste0(name[append_pos], "..", append_pos)
  name
}
