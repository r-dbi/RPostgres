context("exotic types")

test_that("can manipulate classes", {
  expect_is(set_class(1, "A"), "A")
  expect_is(append_class(1, "A"), "A")
  expect_is(yank_class(append_class(1, "A")), "numeric")
})

test_that("`dbColumnInfo` knows about typnames", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  z <- dbSendQuery(con, "SELECT 1 as a, '[1,2,3]'::json as js")
  expect_equal(dbColumnInfo(z)[["typname"]], c("int4", "json"))
})

test_that("can finalize special types", {
  df_ <- data.frame(a = 1, js = "[1,2,3]", stringsAsFactors = FALSE)
  df <- dbGetQuery(con, "SELECT 1 as a, '[1,2,3]'::json as js")
  expect_equal(df, df_)

  finalizeType.json <- function(x, ...) {
    lapply(x, jsonlite::fromJSON)
  }

  df_$js <- list(1:3); row.names(df_) <- 1L
  df <- dbGetQuery(con, "SELECT 1 as a, '[1,2,3]'::json as js")
  expect_equal(df, df_)
})
