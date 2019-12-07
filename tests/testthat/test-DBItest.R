if (postgresHasDefault() && identical(Sys.getenv("NOT_CRAN"), "true")) {

DBItest::test_all()

}
