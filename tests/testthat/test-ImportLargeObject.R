
test_that("can import and read a large object", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- file.path(test_path(), "data", "large_object.txt")
  dbWithTransaction(con, {
    oid <- postgresImportLargeObject(con, test_file_path)
  })
  expect_gt(oid, 0)
  lo_data           <- unlist(dbGetQuery(con, "select lo_get($1) as lo_data", params = list(oid))$lo_data[1])
  large_object_txt  <- as.raw(c(0x70, 0x6f, 0x73, 0x74, 0x67, 0x72, 0x65, 0x73)) # the string "postgres"
  expect_equal(lo_data, large_object_txt)
})


test_that("can import and export a large object", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- file.path(test_path(), "data", "large_object.txt")

  # Import the large object
  oid <- dbWithTransaction(con, {
    postgresImportLargeObject(con, test_file_path)
  })
  expect_gt(oid, 0)

  # Export to a temporary file
  temp_file <- tempfile(fileext = ".txt")
  on.exit(unlink(temp_file), add = TRUE)

  dbWithTransaction(con, {
    postgresExportLargeObject(con, oid, temp_file)
  })

  # Verify the exported file exists and has correct content
  expect_true(file.exists(temp_file))
  exported_content <- readBin(temp_file, "raw", file.size(temp_file))
  original_content <- readBin(test_file_path, "raw", file.size(test_file_path))
  expect_equal(exported_content, original_content)

  # Clean up large object
  dbExecute(con, "SELECT lo_unlink($1)", params = list(oid))
})


test_that("importing to an existing oid throws error", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- file.path(test_path(), "data", "large_object.txt")
  oid <- 1234
  dbWithTransaction(con, {
    oid <- postgresImportLargeObject(con, test_file_path, oid)
  })

  expect_error(
    dbWithTransaction(con, {
      oid <- postgresImportLargeObject(con, test_file_path, oid)
    })
  )
  dbExecute(con, "select lo_unlink($1) as lo_data", params = list(oid))
})


test_that("import from a non-existing path throws error", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- file.path(test_path(), "data", "large_object_that_does_not_exist.txt")
  expect_error(
    dbWithTransaction(con, {
      oid <- postgresImportLargeObject(con, test_file_path)
    })
  )
})


test_that("export outside transaction throws error", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  expect_error(
    postgresExportLargeObject(con, 12345, tempfile()),
    "Cannot export a large object outside of a transaction"
  )
})


test_that("export with NULL oid throws error", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  expect_error(
    dbWithTransaction(con, {
      postgresExportLargeObject(con, NULL, tempfile())
    }),
    "'oid' cannot be NULL"
  )
})


test_that("export with NA oid throws error", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  expect_error(
    dbWithTransaction(con, {
      postgresExportLargeObject(con, NA, tempfile())
    }),
    "'oid' cannot be NA"
  )
})


test_that("export with negative oid throws error", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  expect_error(
    dbWithTransaction(con, {
      postgresExportLargeObject(con, -1, tempfile())
    }),
    "'oid' cannot be negative"
  )
})


test_that("export of non-existent oid throws error", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))
  temp_file <- tempfile()
  on.exit(unlink(temp_file), add = TRUE)

  expect_error(
    dbWithTransaction(con, {
      postgresExportLargeObject(con, 999999, temp_file)
    })
  )
})
