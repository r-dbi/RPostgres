test_that("WaitForNotify without anything to do returns NULL", {
  db <- postgresDefault()
  n <- RPostgres::postgresWaitForNotify(db, 1)
  dbDisconnect(db)
  expect_null(n)
})

test_that("WaitForNotify with a waiting message returns message", {
  db <- postgresDefault()
  dbExecute(db, 'LISTEN grapevine')
  dbExecute(db, "NOTIFY grapevine, 'psst'")
  n <- RPostgres::postgresWaitForNotify(db, 1)
  dbDisconnect(db)
  expect_identical(n$payload, 'psst')
})
