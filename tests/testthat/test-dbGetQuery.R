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


# Not generic enough for DBItest
test_that("JSONB format is recognized", {

  con <- dbConnect(RPostgres::Postgres())

  jsonb <- '{\"name\": \"mike\"}'

  dbGetQuery(con, "CREATE TEMPORARY TABLE test2 (data JSONB)")
  dbGetQuery(con, paste0("INSERT INTO test2(data) values ('", jsonb, "');"))

  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT * FROM test2")$data, jsonb),
    NA
  )

  dbDisconnect(con)

})


test_that("uuid format is recognized", {

  con <- dbConnect(RPostgres::Postgres())

  dbGetQuery(con, "CREATE TEMPORARY TABLE fuutab
    (
    fuu UUID,
    name VARCHAR(255) NOT NULL
    );")

  uuid <- "c44352c0-72bd-11e5-a7f3-0002a5d5c51b"

  dbGetQuery(con, paste0("INSERT INTO fuutab(fuu, name) values ('", uuid, "', 'bob');"))

  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT * FROM fuutab")$fuu, uuid),
    NA
  )

  dbDisconnect(con)

})
