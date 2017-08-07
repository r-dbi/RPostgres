context("Connection")

test_that("double disconnect throws error", {
  con <- dbConnect(Postgres())
  expect_true(dbDisconnect(con))
  expect_error(dbDisconnect(con), "not valid")
})

test_that("querying closed connection throws error", {
  db <- dbConnect(Postgres())
  dbDisconnect(db)
  expect_error(dbSendQuery(db, "select * from foo"), "not valid")
})

test_that("warn if previous result set is invalidated", {
  con <- dbConnect(Postgres())
  rs1 <- dbSendQuery(con, "SELECT 1 + 1")

  expect_warning(rs2 <- dbSendQuery(con, "SELECT 1 + 1"), "Cancelling previous query")
  expect_false(dbIsValid(rs1))

  dbClearResult(rs2)
})

test_that("no warning if previous result set is closed", {
  con <- dbConnect(Postgres())
  rs1 <- dbSendQuery(con, "SELECT 1 + 1")
  dbClearResult(rs1)

  rs2 <- dbSendQuery(con, "SELECT 1 + 1")
  dbClearResult(rs2)
})

test_that("warning if close connection with open results", {
  con <- dbConnect(Postgres())
  rs1 <- dbSendQuery(con, "SELECT 1 + 1")

  expect_warning(dbDisconnect(con), "still in use")
})

test_that("passing other options parameters", {
  con <- dbConnect(Postgres(), application_name="apple")
  pid <- dbGetInfo(con)$pid
  r <- dbGetQuery(con, "SELECT application_name FROM pg_stat_activity WHERE pid=$1",
                  list(pid=pid))
  expect_identical(r$application_name, "apple")
})

test_that("error if passing unkown parameters", {
  expect_error(dbConnect(Postgres(), fruit="apple"), 'invalid connection option "fruit"')
})
