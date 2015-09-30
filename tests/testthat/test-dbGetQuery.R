context("dbGetQuery")

test_that("special charaters work", {
  angstrom <- enc2utf8("\\u00e5")

  con <- dbConnect(RPostgres::Postgres())

  dbGetQuery(con, "CREATE TEMPORARY TABLE test1 (x TEXT)")
  dbGetQuery(con, "INSERT INTO test1 VALUES ('\\u00e5')")

  expect_equal(dbGetQuery(con, "SELECT * FROM test1")$x, angstrom)
  expect_equal(dbGetQuery(con, "SELECT * FROM test1 WHERE x = '\\u00e5'")$x,
    angstrom)
})


test_that("JSONB format is recognized", {

  con <- dbConnect(RPostgres::Postgres())

  dbGetQuery(con, "CREATE TEMPORARY TABLE test2 (data JSONB)")
  dbGetQuery(con, "INSERT INTO test2(data) values ('{\"name\":\"mike\"}');")

  expect_that(dbGetQuery(con, 'SELECT * FROM test2'), not(gives_warning()))

})
