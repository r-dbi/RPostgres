if (Sys.getenv("GITHUB_ACTIONS") == "true" || (postgresHasDefault() && identical(Sys.getenv("NOT_CRAN"), "true"))) {

DBItest::test_all()

}
