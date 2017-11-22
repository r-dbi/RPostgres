DBItest::test_all(c(
  # deliberately skipped, not required with next version of DBI
  "get_info_driver",
  "get_info_connection",
  "get_info_result",

  # result
  "data_raw",                                   # not a failure, can't cast to raw

  # sql
  "roundtrip_64_bit_.*",                        # rstats-db/DBI#48, #51
  "roundtrip_64_bit_character",                 # rstats-db/DBI#48, #51

  # meta
  "is_valid_connection",                        # #64
  "column_info",                                # #50
  "bind_multi_row.*",                           # #100
  "bind_repeated.*",                            # #87
  "is_valid_stale_connection",

  # transactions
  "commit_without_begin",                       # #98
  "rollback_without_begin",                     # #98
  "begin_begin",                                # #98
  "with_transaction_error_nested",

  NULL
))
