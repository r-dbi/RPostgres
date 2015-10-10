DBItest::make_context(Postgres(), NULL)
DBItest::test_all(c(
  "package_dependencies", # #47
  "data_type",            # #48
  "show",                 # #49
  "get_info",             # to be discussed
  "data_null",            # #50
  "data_64_bit"           # #51
))
