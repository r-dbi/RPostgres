DBItest::test_all(c(
  # driver
  "get_info_driver",                            # rstats-db/RSQLite#117

  # connection
  "get_info_connection",                        # rstats-db/RSQLite#117
  "cannot_disconnect_twice",                    # TODO

  # result
  "clear_result_return",                        # error: need to warn if closing result twice
  "data_type_connection",                       # #66
  "data_logical_int",                           # not an error, full support for boolean data type
  "data_logical_int_null_.*",                   # not an error, full support for boolean data type
  "data_null",                                  # #50
  "data_64_bit",                                # #51
  "data_64_bit_null_.*",                        # #51
  "data_character",                             # #50
  "data_raw",                                   # #66
  "data_raw_null_.*",                           # #66
  "data_date",                                  # #52
  "data_date_null_.*",                          # #52
  "data_time_parens",                           # syntax not supported
  "data_time_parens_null_.*",                   # syntax not supported
  "data_timestamp",                             # #53
  "data_timestamp_null_.*",                     # #53
  "data_timestamp_utc",                         # #53
  "data_timestamp_utc_null_.*",                 # #53
  "data_timestamp_parens",                      # syntax not supported
  "data_timestamp_parens_null_.*",              # syntax not supported

  # sql
  "quote_string",                               # #50
  "append_table_error",                         # #62
  "list_fields",                                # #79
  "fetch_single",                               # #65
  "fetch_multi_row_single_column",              # #65
  "fetch_progressive",                          # #65
  "fetch_more_rows",                            # #65
  "fetch_closed",                               # #65
  "quote_identifier_not_vectorized",            # rstats-db/DBI#24
  "roundtrip_logical_int",                      # not an error, full support for boolean data type
  "roundtrip_64_bit",                           # rstats-db/DBI#48
  "roundtrip_raw",                              # #66
  "roundtrip_date",                             # #61
  "roundtrip_timestamp",                        # #61

  # meta
  "is_valid_connection",                        # #64
  "get_exception",                              # #63
  "get_info_result",                            # rstats-db/DBI#55
  "column_info",                                # #50
  "bind_empty.*",                               # #70
  "bind_multi_row.*",                           # #100
  "bind_logical_int.*",                         # not an error, logicals supported natively
  "bind_raw.*",                                 # 66
  "bind_null.*",                                # 67
  "bind_repeated.*",                            # 87
  "bind_timestamp.*",                           # 53
  "bind_timestamp_lt.*",                        # 53
  "bind_statement_repeated",                    # 102

  # transactions
  "commit_without_begin",                       # 98
  "begin_begin",                                # 98

  # compliance
  "compliance",                                 # #68
  "ellipsis",                                   # #101
  "read_only",                                  # default connection is read-write
  NULL
))
