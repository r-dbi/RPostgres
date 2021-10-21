context("isTransacting")

test_that("isTransacting detects transactions correctly", {
  skip_on_cran()
  db <- postgresDefault()
  expect_fale(postgresIsTransacting(con))
  dbBegin(con)
  expect_true(postgresIsTransacting(con))
  dbCommit(con)
  expect_fale(postgresIsTransacting(con))
})
