DBItest::test_all(c(
  # driver
  "get_info_driver",                            # rstats-db/RSQLite#117

  # connection
  "get_info_connection",                        # rstats-db/RSQLite#117

  # result
  "data_64_bit_.*",                             # #51
  "data_raw",                                   # not a failure, can't cast to raw

  # sql
  "roundtrip_64_bit_.*",                        # rstats-db/DBI#48, #51
  "roundtrip_64_bit_character",                 # rstats-db/DBI#48, #51

  # meta
  "is_valid_connection",                        # #64
  "get_statement_error",                        #
  "rows_affected_query",                        #
  "get_info_result",                            # rstats-db/DBI#55
  "column_info",                                # #50
  "bind_multi_row.*",                           # #100
  "bind_logical",                               #
  "bind_return_value",
  "bind_blob",
  "bind_named_param.*",
  "bind_named_param_unnamed_placeholders",
  "bind_unnamed_param_named_placeholders",
  "bind_return_value",
  "bind_integer",
  "bind_numeric",
  "bind_character",
  "bind_date",                                  # #24
  "bind_factor",
  "bind_raw.*",                                 # #66
  "bind_repeated.*",                            # #87
  "bind_timestamp.*",                           # #53
  "bind_timestamp_lt.*",                        # #53
  "is_valid_stale_connection",

  # transactions
  "commit_without_begin",                       # #98
  "rollback_without_begin",                     # #98
  "begin_begin",                                # #98
  "with_transaction_error_nested",

  # compliance
  "compliance",                                 # #68
  "ellipsis",                                   # #101

  NULL
))
