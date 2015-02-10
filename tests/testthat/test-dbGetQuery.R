context("dbGetQuery")

test_that("special charaters work", {
  angstrom <- enc2utf8("å")
  con <- dbConnect(RSQLite::SQLite())

  dbGetQuery(con, "CREATE TABLE test1 (x CHARACTER)")
  dbGetQuery(con, "INSERT INTO test1 VALUES ('å')")

  expect_equal(dbGetQuery(con, "SELECT * FROM test1")$x, angstrom)
  expect_equal(dbGetQuery(con, "SELECT * FROM test1 WHERE x = 'å'")$x,
    angstrom)
})
