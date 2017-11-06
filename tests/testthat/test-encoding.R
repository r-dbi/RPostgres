context("Encoding")

# Specific to RPostgres
test_that("NAs encoded as NULLs", {
  expect_equal(encode_vector(NA), "\\N")
  expect_equal(encode_vector(NA_integer_), "\\N")
  expect_equal(encode_vector(NA_real_), "\\N")
  expect_equal(encode_vector(NA_character_), "\\N")
})

# Specific to RPostgres
test_that("special floating point values encoded correctly", {
  expect_equal(encode_vector(NaN), "NaN")
  expect_equal(encode_vector(Inf), "Infinity")
  expect_equal(encode_vector(-Inf), "-Infinity")
})

# Specific to RPostgres
test_that("special string values are escaped", {
  expect_equal(encode_vector("\n"), "\\n")
  expect_equal(encode_vector("\r"), "\\r")
  expect_equal(encode_vector("\b"), "\\b")
})
