test_that("integer64 values are treated as bigints, not floats", {
  con <- postgresDefault()

  x <- structure(4.94065645841247e-324, class = "integer64")

  expect_equal(
    as.character(dbQuoteLiteral(con, x)),
    "1::int8"
  )
})
