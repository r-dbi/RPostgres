if (identical(Sys.getenv("NOT_CRAN"), "true")) {

DBItest::test_all(c(
  # deliberately skipped, not required with upcoming version of DBI
  "get_info_driver",
  "get_info_connection",
  "get_info_result",

  NULL
))

}
