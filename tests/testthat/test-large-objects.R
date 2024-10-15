test_that("can write and read a large object", {
  con       <- postgresDefault()
  oid       <- dbGetQuery(con, "select lo_create(0) as oid")$oid[1]
  data      <- "test string"
  raw_data  <- serialize(data,NULL)
  dbWithTransaction(con,{
    bytes_written <- postgresWriteToLargeObject(con,oid,raw_data,length(raw_data))
  })
  result    <- dbGetQuery(con, "select lo_get($1) as lo_data", params=list(oid))
  expect_equal(unserialize(unlist(result$lo_data[1])), data)
  expect_equal(length(raw_data),bytes_written)
})


test_that("can import and read a large object", {
  con       <- postgresDefault()
  test_file_path <- paste0(test_path(),'/data/large_object.txt')
  dbWithTransaction(con, { 
    oid <- postgresImportLargeObject(con, test_file_path)
  })
  expect_gt(oid,0)
  lo_data           <- unlist(dbGetQuery(con, "select lo_get($1) as lo_data", params=list(oid))$lo_data[1])
  large_object_txt  <- as.raw(c(0x70, 0x6f, 0x73, 0x74, 0x67, 0x72, 0x65, 0x73)) # the string 'postgres'
  expect_equal(lo_data, large_object_txt)
})
