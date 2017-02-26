DBItest::test_all(c(
  # driver
  "get_info_driver",                            # rstats-db/RSQLite#117

  # connection
  "get_info_connection",                        # rstats-db/RSQLite#117
  "cannot_disconnect_twice",                    # TODO

  # result
  "cannot_clear_result_twice_.*",               #
  "fetch_n_bad",                                #
  "fetch_n_good_after_bad",                     #
  "fetch_no_return_value",                      #
  "send_query_syntax_error",                    #
  "get_query_n_.*",                             #
  "get_query_syntax_error",                     #
  "clear_result_return",                        # error: need to warn if closing result twice
  "data_type_connection",                       # #66
  "data_logical_int",                           # not an error, full support for boolean data type
  "data_logical_int_null_.*",                   # not an error, full support for boolean data type
  "data_null",                                  # #50
  "data_64_bit_.*",                             # #51
  "data_character",                             # #50
  "data_raw",                                   # #66
  "data_raw_null_.*",                           # #66
  "data_date_typed",                            # #52
  "data_date_current_typed",                    # #52
  "data_timestamp",                             #
  "data_timestamp_typed",                       # #53
  "data_timestamp_current_typed",               # #53
  "data_timestamp_utc_typed",                   # #53
  "data_timestamp_null_.*",                     # #53

  # sql
  "quote_string.*",                             # #50
  "quote_identifier_vectorized",                #
  "quote_identifier_special",                   #
  "append_table_error",                         # #62
  "list_fields",                                # #79
  "fetch_single",                               # #65
  "fetch_multi_row_single_column",              # #65
  "fetch_progressive",                          # #65
  "fetch_more_rows",                            # #65
  "fetch_closed",                               # #65
  "quote_identifier_not_vectorized",            # rstats-db/DBI#24
  "write_table_name",                           #
  "roundtrip_quotes",                           #
  "list_tables",                                #
  "exists_table_list",                          #
  "roundtrip_keywords",                         #
  "roundtrip_64_bit",                           # rstats-db/DBI#48
  "roundtrip_raw",                              # #66
  "roundtrip_date",                             # #61
  "roundtrip_time",                             # #61
  "roundtrip_timestamp",                        # #61
  "roundtrip_numeric_special",                  #
  "read_table_check_names",                     #
  "read_table_error",                           #
  "read_table_name",                            #
  "write_table_error",                          #
  "exists_table_error",                         #
  "exists_table_name",                          #
  "remove_table_name",                          #

  # meta
  "is_valid_connection",                        # #64
  "get_statement_error",                        #
  "has_completed_query",                        #
  "has_completed_error",                        #
  "rows_affected_query",                        #
  "get_exception",                              # #63
  "get_info_result",                            # rstats-db/DBI#55
  "column_info",                                # #50
  "bind_empty.*",                               # #70
  "bind_multi_row.*",                           # #100
  "bind_logical",                               #
  "bind_wrong_name",                            #
  "bind_raw.*",                                 # 66
  "bind_null.*",                                # 67
  "bind_repeated.*",                            # 87
  "bind_timestamp.*",                           # 53
  "bind_timestamp_lt.*",                        # 53
  "bind_statement_repeated",                    # 102

  # transactions
  "commit_without_begin",                       # 98
  "rollback_without_begin",                     # 98
  "begin_begin",                                # 98
  "begin_write_disconnect",                     #

  # compliance
  "compliance",                                 # #68
  "ellipsis",                                   # #101
  "read_only",                                  # default connection is read-write
  NULL
))
