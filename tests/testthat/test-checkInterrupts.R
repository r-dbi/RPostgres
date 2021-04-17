context("checkInterrupts")

test_that("Query is executed properly when check_interrupts connection option is 
          set to TRUE and query execution takes more than check user interrupts 
          timeout (1 second)", {
  con <- postgresDefault(check_interrupts = TRUE)
  expect_equal(dbGetQuery(con, "SELECT pg_sleep(2), 'foo' AS x")$x, "foo")
  dbDisconnect(con)
  expect_null(n)
})
