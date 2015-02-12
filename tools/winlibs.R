# Build against static libpq
if(!file.exists("../windows/libpq-9.4.1/include/libpq-fe.h")){
  # internet2.dll supports https
  setInternet2()
  download.file("https://github.com/rwinlib/libpq/archive/v9.4.1.zip", "lib.zip", quiet = TRUE)
  dir.create("../windows", showWarnings = FALSE)
  unzip("lib.zip", exdir = "../windows")
  unlink("lib.zip")
}
