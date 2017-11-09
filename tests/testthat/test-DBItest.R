DBItest::test_all(c(
  # driver
  "get_info_driver",                            # rstats-db/RSQLite#117

  # connection
  "get_info_connection",                        # rstats-db/RSQLite#117

  # result
  "send_query_syntax_error",                    # DBItest > 1.5-21
  "get_query_syntax_error",                     # DBItest > 1.5-21
  "data_null",                                  # DBItest > 1.5-21
  "data_64_bit_.*",                             # #51
  "data_character",                             # not a failure, need to do `SELECT "a"::varchar`
  "data_raw",                                   # not a failure, can't cast to raw

  # sql
  "quote_string.*",                             # #50
  "quote_identifier_vectorized",                #
  "quote_identifier_special",                   #
  "list_fields",                                # #79
  "write_table_name",                           #
  "list_tables",                                #
  "roundtrip_keywords",                         #
  "roundtrip_64_bit_.*",                        # rstats-db/DBI#48, #51
  "roundtrip_64_bit_character",                 # rstats-db/DBI#48, #51
  "roundtrip_raw",                              # #66
  "roundtrip_blob",                             # #66
  "roundtrip_time",                             # #61
  "roundtrip_logical",                          #
  "roundtrip_quotes",                           #
  "roundtrip_null",                             #
  "roundtrip_numeric",                          #
  "roundtrip_integer",                          #
  "roundtrip_date",                             # #24, #61
  "roundtrip_factor",                           #
  "roundtrip_character",                        #
  "roundtrip_character_empty",                  #
  "roundtrip_character_native",                 #
  "roundtrip_mixed",                            #

  "roundtrip_timestamp",                        # #61, #104
  "roundtrip_field_types",                      #

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
  "rows_affected_query",                        #
  "rows_affected_statement",
  "row_count_statement",
  "get_info_result",                            # rstats-db/DBI#55
  "column_info",                                # #50
  "bind_empty.*",                               # #70, #95
  "bind_multi_row.*",                           # #100
  "bind_logical",                               #
  "bind_return_value",
  "bind_too_many",
  "bind_not_enough",
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
  "bind_wrong_name",                            #
  "bind_raw.*",                                 # #66
  "bind_repeated.*",                            # #87
  "bind_timestamp.*",                           # #53
  "bind_timestamp_lt.*",                        # #53
  "is_valid_stale_connection",

  # transactions
  "commit_without_begin",                       # #98
  "rollback_without_begin",                     # #98
  "begin_begin",                                # #98
  "begin_write_disconnect",                     #
  "with_transaction_error_nested",

  # compliance
  "compliance",                                 # #68
  "ellipsis",                                   # #101

  # visibility
  "can_disconnect",
  "write_table_return",                         # #62
  "remove_table_return",
  "clear_result_return_.*",

  NULL
))
