DBItest::make_context(Postgres(), NULL)
DBItest::test_all(c(
  "package_dependencies",  # #47
  "data_type",             # #48
  "show",                  # #49
  "get_info",              # to be discussed
  "data_logical_int",      # not an error, full support for boolean data type
  "data_logical_int_null", # not an error, full support for boolean data type
  "data_null",             # #50
  "data_64_bit",           # #51
  "data_64_bit_null",      # #51
  "data_character",        # #50
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
  "roundtrip_logical",     # #60
  "roundtrip_64_bit",      # rstats-db/DBI#48
  "roundtrip_date",        # #61
  "roundtrip_timestamp",   # #61
  NULL
))
