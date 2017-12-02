context("bigint")

if (identical(Sys.getenv("NOT_CRAN"), "true")) {

test_that("integer", {
  con <- dbConnect(Postgres(), bigint = "integer")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], 1L)
})

test_that("numeric", {
  con <- dbConnect(Postgres(), bigint = "numeric")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], 1.0)
})

test_that("character", {
  con <- dbConnect(Postgres(), bigint = "character")
  on.exit(dbDisconnect(con))

  expect_identical(dbGetQuery(con, "SELECT COUNT(*) FROM (SELECT 1) A")[[1]], "1")
})

}
