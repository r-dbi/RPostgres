astyle <- function(extra_args = character()) {
  astyle_cmd <- "astyle"
  if (Sys.which(astyle_cmd) == "") {
    skip("astyle not found")
  }

  astyle_args <- c(
    "-n",
    "--indent=spaces=2",
    "--indent-cases",
    "--unpad-paren",
    "--pad-header",
    "--pad-oper",
    "--min-conditional-indent=0",
    "--align-pointer=type",
    "--align-reference=type"
  )

  tryCatch(
    {
      src_path <- testthat::test_path("../../src")
      src_path <- normalizePath(src_path)
    },
    warning = function(e) {
      skip(paste0("Sources not found: ", conditionMessage(e)))
    },
    error = function(e) {
      skip(paste0("Sources not found: ", conditionMessage(e)))
    }
  )
  src_files <- dir(src_path, "[.](?:cpp|h)$", recursive = FALSE, full.names = TRUE)
  astyle_files <- grep("(?:RcppExports[.]cpp)", src_files, value = TRUE, invert = TRUE)
  output <- system2(astyle_cmd, c(astyle_args, astyle_files, extra_args), stdout = TRUE, stderr = TRUE)
  unchanged <- grepl("^Unchanged", output)
  if (any(!unchanged)) {
    warning(paste(output[!unchanged], collapse = "\n"))
  }
}
