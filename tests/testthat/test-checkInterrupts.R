context("checkInterrupts")

test_that("check_interrupts = TRUE works with queries > 1 second (#244)", {
  con <- postgresDefault(check_interrupts = TRUE)
  expect_equal(dbGetQuery(con, "SELECT pg_sleep(2), 'foo' AS x")$x, "foo")
  dbDisconnect(con)
})
