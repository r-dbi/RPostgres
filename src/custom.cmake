target_include_directories(RPostgres PUBLIC
    "/usr/include/postgresql"
    "vendor"
)

target_compile_definitions(RPostgres PUBLIC
    "RCPP_DEFAULT_INCLUDE_CALL=false"
    "RCPP_USING_UTF8_ERROR_STRING"
    "BOOST_NO_AUTO_PTR"
)
