test_that("isTransacting detects transactions correctly", {
  skip_on_cran()
  con <- postgresDefault()
  expect_false(postgresIsTransacting(con))
  dbBegin(con)
  expect_true(postgresIsTransacting(con))
  dbCommit(con)
  expect_false(postgresIsTransacting(con))
})
