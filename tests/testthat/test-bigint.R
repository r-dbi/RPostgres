context("bigint")

test_that("integer", {
  con <- postgresDefault(bigint = "integer")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], 1L)
})

test_that("numeric", {
  con <- postgresDefault(bigint = "numeric")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], 1.0)
})

test_that("character", {
  con <- postgresDefault(bigint = "character")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], "1")
})
