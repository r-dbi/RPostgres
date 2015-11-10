DBItest::make_context(Postgres(), NULL)
DBItest::test_all(c(
  "package_dependencies",  # #47
  "show",                  # #49
  "get_info",              # to be discussed
  "data_type_connection",  # #66
  "data_logical_int",      # not an error, full support for boolean data type
  "data_logical_int_null", # not an error, full support for boolean data type
  "data_null",             # #50
  "data_64_bit",           # #51
  "data_64_bit_null",      # #51
  "data_character",        # #50
  "data_raw",              # #66
  "data_raw_null",         # #66
  "data_date",             # #52
  "data_date_null",        # #52
  "data_time_parens",      # syntax not supported
  "data_time_parens_null", # syntax not supported
  "data_timestamp",        # #53
  "data_timestamp_null",   # #53
  "data_timestamp_utc",    # #53
  "data_timestamp_utc_null", # #53
  "data_timestamp_parens", # syntax not supported
  "data_timestamp_parens_null", # syntax not supported
  "quote_string",          # #50
  "append_table_error",    # #62
  "fetch_single",          # #65
  "fetch_multi_row_single_column", # #65
  "fetch_progressive",     # #65
  "fetch_more_rows",       # #65
  "fetch_closed",          # #65
  "roundtrip_logical",     # #60
  "roundtrip_64_bit",      # rstats-db/DBI#48
  "roundtrip_raw",         # #66
  "roundtrip_date",        # #61
  "roundtrip_timestamp",   # #61
  "is_valid",              # #64
  "get_exception",         # #63
  "bind_.*_positional_qm", # no error, syntax not supported
  "bind_.*_named_.*",      # no error, syntax not supported
  "bind_logical_int_positional_dollar", # not an error, logicals supported natively
  "bind_raw_positional_dollar", # 66
  "bind_null_positional_dollar", # 67
  "bind_timestamp_positional_dollar", # 53
  "bind_timestamp_lt_positional_dollar", # 53
  NULL
))
