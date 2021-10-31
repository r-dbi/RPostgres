test_that("multiplication works", {

  con <- tryCatch({
    dbConnect(Redshift())
  }, error = function(...) {
    testthat::skip("Test database not available")
  })

  expect_s4_class(con, "RedshiftConnection")
  dbDisconnect(con)
})
