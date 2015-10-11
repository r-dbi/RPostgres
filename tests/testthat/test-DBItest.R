DBItest::make_context(Postgres(), NULL)
DBItest::test_all(c(
  "package_dependencies",  # #47
  "data_type",             # #48
  "show",                  # #49
  "get_info",              # to be discussed
  "data_null",             # #50
  "data_64_bit",           # #51
  "data_character",        # #50
  "data_date",             # #52
  "data_time_parens",      # syntax not supported
  "data_timestamp",        # #53
  "data_timestamp_utc",    # #53
  "data_timestamp_parens", # syntax not supported
  "quote_string",          # #50
  NULL
))
