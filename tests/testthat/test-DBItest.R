if (
  Sys.getenv("GITHUB_ACTIONS") == "true" ||
    (postgresHasDefault() && identical(Sys.getenv("NOT_CRAN"), "true"))
) {
  if (rlang::is_installed("DBItest")) {
    DBItest::test_all()
  }
}
