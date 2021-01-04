test_that("timestamp without time zone is returned correctly for TZ set (#190)", {
  withr::local_timezone("America/Chicago")

  query <- "SELECT '2018-01-01 12:30:00'::TIMESTAMP AS a, '2018-01-01 12:30:00'::TIMESTAMPTZ AS b"

  db <- postgresDefault(timezone = NULL)
  res <- dbGetQuery(db, query)
  expect_equal(res[[1]], res[[2]])
  dbDisconnect(db)

  db <- postgresDefault(timezone = "UTC")
  expect_equal(
    dbGetQuery(db, query)[[1]],
    as.POSIXct("2018-01-01 12:30:00", tz = "UTC")
  )
  dbDisconnect(db)

  db <- postgresDefault(timezone = "America/Chicago")
  expect_equal(
    dbGetQuery(db, query)[[1]],
    as.POSIXct("2018-01-01 12:30:00", tz = "America/Chicago")
  )
  dbDisconnect(db)

  db <- postgresDefault(timezone = "America/New_York")
  expect_equal(
    dbGetQuery(db, query)[[1]],
    as.POSIXct("2018-01-01 12:30:00", tz = "America/New_York")
  )
  dbDisconnect(db)

  db <- postgresDefault(timezone = "Europe/London")
  expect_equal(
    dbGetQuery(db, query)[[1]],
    as.POSIXct("2018-01-01 12:30:00", tz = "Europe/London")
  )
  dbDisconnect(db)

  db <- postgresDefault(timezone = "Europe/Zurich")
  expect_equal(
    dbGetQuery(db, query)[[1]],
    as.POSIXct("2018-01-01 12:30:00", tz = "Europe/Zurich")
  )
  dbDisconnect(db)
})

test_that("timestamp with time zone is returned correctly (#205)", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  withr::local_timezone("America/New_York")

  con <- postgresDefault(timezone = "America/Chicago")

  query <- "CREATE TEMPORARY TABLE junk AS
            (SELECT '2020-05-04'::TIMESTAMPTZ AS ts)"
  res <- dbExecute(con, query)

  res <- dbGetQuery(con, "SELECT * FROM junk")
  expect_equal(res[[1]], as.POSIXct("2020-05-04", tz = "America/Chicago"))
})

test_that("timestamp with time zone is returned correctly for time zones", {
  con <- postgresDefault(timezone = "Europe/Zurich", timezone_out = "UTC")
  on.exit(dbDisconnect(con))

  query <- "SELECT '1970-01-01 12:00:00+00:00'::TIMESTAMPTZ AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "UTC"))
})

test_that("timestamp with time zone is returned correctly for half-hour time zones", {
  con <- postgresDefault(timezone = "Asia/Calcutta", timezone_out = "UTC")
  on.exit(dbDisconnect(con))

  query <- "SELECT '1970-01-01 12:00:00+00:00'::TIMESTAMPTZ AS ts"
  res <- dbGetQuery(con, query)
  expect_equal(res[[1]], as.POSIXct("1970-01-01 12:00:00", tz = "UTC"))
})

test_that("timestamp without time zone is returned correctly (#221)", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  out <- dbGetQuery(con, "SELECT CAST('1960-01-01 12:00:00' AS timestamp) AS before_epoch")
  expect_equal(as.Date(out[[1]]), as.Date("1960-01-01"))
})

test_that("timezone is passed on to the connection (#229)", {
  my_tz <- "US/Alaska"

  con <- postgresDefault(timezone = my_tz)
  on.exit(dbDisconnect(con))

  example <- data.frame(val = 0:71)
  example$ts <-
    lubridate::ymd_hms("2019-04-30 00:00:00", tz = my_tz) +
    lubridate::hours(example$val)

  dbWriteTable(
    con, "example", example, temporary = TRUE,
    overwrite = TRUE, append = FALSE
  )

  query <- '
    SELECT date("ts") AS "dte", MIN("val") AS "min", MAX("val") AS "max"
    FROM "example"
    GROUP BY "dte"
    ORDER BY "dte"'
  expected <- data.frame(
    dte = as.Date("2019-04-30") + 0:2,
    min = 0:2 * 24,
    max = 0:2 * 24 + 23
  )

  res <- dbGetQuery(con, query)
  expect_equal(res, expected)
})

test_that("warning if time zone not interpretable", {
  skip_on_cran()

  expect_warning(con <- postgresDefault(timezone = "+01:00"))
  dbDisconnect(con)
  expect_warning(con <- postgresDefault(timezone_out = "+01:00"))
  dbDisconnect(con)
})
