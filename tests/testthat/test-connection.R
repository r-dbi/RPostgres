context("Connection")

test_that("double disconnect doesn't crash", {
  con <- dbConnect(pq())
  expect_true(dbDisconnect(con))
  expect_true(dbDisconnect(con))
})
