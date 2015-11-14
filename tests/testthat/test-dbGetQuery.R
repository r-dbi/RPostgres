context("dbGetQuery")

# Not generic enough for DBItest
test_that("JSONB format is recognized", {

  con <- dbConnect(RPostgres::Postgres())

  dbGetQuery(con, "CREATE TEMPORARY TABLE test2 (data JSONB)")
  dbGetQuery(con, "INSERT INTO test2(data) values ('{\"name\":\"mike\"}');")

  expect_that(dbGetQuery(con, 'SELECT * FROM test2'), not(gives_warning()))

})
