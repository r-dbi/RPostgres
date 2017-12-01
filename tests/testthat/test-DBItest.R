DBItest::test_all(c(
  # deliberately skipped, not required with next version of DBI
  "get_info_driver",
  "get_info_connection",
  "get_info_result",

  # result
  "data_raw",                                   # not a failure, can't cast to raw

  # meta
  "bind_raw",                                   #
  "bind_blob",                                  #

  NULL
))
