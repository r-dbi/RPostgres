
test_that("can import and read a large object", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- paste0(test_path(),'/data/large_object.txt')
  dbWithTransaction(con, { oid <- postgresImportLargeObject(con, test_file_path) })
  expect_gt(oid,0)
  lo_data           <- unlist(dbGetQuery(con, "select lo_get($1) as lo_data", params=list(oid))$lo_data[1])
  large_object_txt  <- as.raw(c(0x70, 0x6f, 0x73, 0x74, 0x67, 0x72, 0x65, 0x73)) # the string 'postgres'
  expect_equal(lo_data, large_object_txt)
})


test_that("importing to an existing oid throws error", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- paste0(test_path(),'/data/large_object.txt')
  oid <- 1234
  dbWithTransaction(con, { oid <- postgresImportLargeObject(con, test_file_path, oid) })

  expect_error(
    dbWithTransaction(con, { oid <- postgresImportLargeObject(con, test_file_path, oid) })
  )
  dbExecute(con, "select lo_unlink($1) as lo_data", params=list(oid))
})


test_that("import from a non-existing path throws error", {
  con       <- postgresDefault()
  on.exit(dbDisconnect(con))
  test_file_path <- paste0(test_path(),'/data/large_object_that_does_not_exist.txt')
  expect_error( 
    dbWithTransaction(con, { oid <- postgresImportLargeObject(con, test_file_path) })
  )
})


