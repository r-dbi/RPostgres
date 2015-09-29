context("dbGetQuery")

test_that("special characters work", {
  angstrom <- enc2utf8("\\u00e5")
  con <- dbConnect(RPostgres::Postgres())

  dbGetQuery(con, "CREATE TEMPORARY TABLE test1 (x TEXT)")
  dbGetQuery(con, "INSERT INTO test1 VALUES ('\\u00e5')")

  expect_equal(dbGetQuery(con, "SELECT * FROM test1")$x, angstrom)
  expect_equal(dbGetQuery(con, "SELECT * FROM test1 WHERE x = '\\u00e5'")$x,
    angstrom)
})
