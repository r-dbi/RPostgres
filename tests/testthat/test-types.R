context("exotic types")

test_that("can manipulate classes", {
  expect_is(set_class(1, "A"), "A")
  expect_is(append_class(1, "A"), "A")
})

test_that("`dbColumnInfo` knows about typnames", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  z <- dbSendQuery(con, "SELECT 1 as a, '[1,2,3]'::json as js")
  expect_equal(dbColumnInfo(z)[["typname"]], c("int4", "json"))
})
