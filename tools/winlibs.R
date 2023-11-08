if(!file.exists("../src/windows/libpq/include/libpq-fe.h")){
  unlink("../src/windows", recursive = TRUE)
  url <- if(grepl("aarch", R.version$platform)){
    "https://github.com/r-windows/bundles/releases/download/libpq-15.3/libpq-15.3-clang-aarch64.tar.xz"
  } else if(grepl("clang", Sys.getenv('R_COMPILED_BY'))){
    "https://github.com/r-windows/bundles/releases/download/libpq-15.3/libpq-15.3-clang-x86_64.tar.xz"
  }  else if(getRversion() >= "4.2") {
    "https://github.com/r-windows/bundles/releases/download/libpq-15.3/libpq-15.3-ucrt-x86_64.tar.xz"
  } else {
    "https://github.com/rwinlib/libpq/archive/v13.2.0.tar.gz"
  }
  download.file(url, basename(url), quiet = TRUE)
  dir.create("../src/windows", showWarnings = FALSE)
  untar(basename(url), exdir = "../src/windows", tar = 'internal')
  unlink(basename(url))
  setwd("../src/windows")
  file.rename(list.files(), 'libpq')
}
