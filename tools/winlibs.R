# Build against static libpq
if(!file.exists("../windows/libpq-9.4.1/include/libpq-fe.h")){
  setInternet2()
  curl::curl_download("https://github.com/rwinlib/libpq/archive/v9.4.1.zip", "lib.zip", quiet = TRUE, mode = "wb")
  dir.create("../windows", showWarnings = FALSE)
  unzip("lib.zip", exdir = "../windows")
  unlink("lib.zip")
}
