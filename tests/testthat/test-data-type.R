context("dbDataType")

# Taken from DBI
test_that("dbDataType works on a data frame", {
  con <- dbConnect(Postgres())
  df <- data.frame(x = 1:10, y = 1:10 / 2)
  types <- dbDataType(con, df)

  expect_equal(types, c(x = "INTEGER", y = "REAL"))

})
