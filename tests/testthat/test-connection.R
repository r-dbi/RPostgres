context("Connection")

test_that("double disconnect doesn't crash", {
  con <- dbConnect(pq())
  expect_true(dbDisconnect(con))
  expect_true(dbDisconnect(con))
})

test_that("querying closed connection throws error", {
  db <- dbConnect(pq())
  dbDisconnect(db)
  expect_error(dbGetQuery(db, "select * from foo"), "not valid")
})

