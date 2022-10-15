test_that("can manipulate classes", {
  expect_is(set_class(1, "A"), "A")
})

test_that("dbColumnInfo() knows about typnames", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  rs <- dbSendQuery(con, "SELECT 1 as a, '[1,2,3]'::json as js")
  expect_equal(dbColumnInfo(rs)[[".typname"]], c("int4", "json"))

  res <- dbFetch(rs)
  expect_is(res$js, "pq_json")

  dbClearResult(rs)
})
