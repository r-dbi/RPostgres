test_that("undefined table error carries SQLSTATE and classed condition", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  cnd <- tryCatch(
    dbGetQuery(con, "SELECT * FROM definitely_no_such_table_579"),
    error = function(e) e
  )
  expect_s3_class(cnd, "RPostgres_error")
  expect_s3_class(cnd, "RPostgres_error_42P01")
  expect_identical(cnd$sqlstate, "42P01")
})

test_that("syntax error carries SQLSTATE 42601", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  cnd <- tryCatch(
    dbGetQuery(con, "SELECT FROM WHERE"),
    error = function(e) e
  )
  expect_identical(cnd$sqlstate, "42601")
})

test_that("RAISE EXCEPTION USING ERRCODE is exposed", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  sql <- "DO $$ BEGIN RAISE EXCEPTION 'boom' USING ERRCODE = 'FS002', HINT = 'fix it'; END $$;"
  cnd <- tryCatch(dbExecute(con, sql), error = function(e) e)

  expect_s3_class(cnd, "RPostgres_error_FS002")
  expect_identical(cnd$sqlstate, "FS002")
  expect_identical(cnd$hint, "fix it")
  expect_match(conditionMessage(cnd), "boom")
})

test_that("classed condition can be caught by SQLSTATE handler", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  handled <- tryCatch(
    dbGetQuery(con, "SELECT * FROM no_such_table_579"),
    RPostgres_error_42P01 = function(e) "caught"
  )
  expect_identical(handled, "caught")
})

test_that("unique constraint violation exposes constraint and SQLSTATE", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  dbExecute(con, "CREATE TEMP TABLE t579 (id int PRIMARY KEY)")
  dbExecute(con, "INSERT INTO t579 VALUES (1)")
  cnd <- tryCatch(
    dbExecute(con, "INSERT INTO t579 VALUES (1)"),
    error = function(e) e
  )
  expect_identical(cnd$sqlstate, "23505")
  expect_false(is.null(cnd$constraint))
})

test_that("error message remains backward compatible", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  cnd <- tryCatch(
    dbGetQuery(con, "SELECT * FROM no_such_table_579"),
    error = function(e) e
  )
  expect_match(conditionMessage(cnd), "does not exist")
})

test_that("server errors are rlang errors with the calling context", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  cnd <- tryCatch(
    dbGetQuery(con, "SELECT * FROM no_such_table_579"),
    error = function(e) e
  )
  expect_s3_class(cnd, "rlang_error")
  # The error is signalled from C++ (detached from the R call stack) and the
  # calling context is restored by rethrow().
  expect_false(is.null(conditionCall(cnd)))
})

test_that("server errors are formatted nicely", {
  local_edition(3)
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  # Drop the server-dependent CONTEXT / LINE / position lines so the snapshot is
  # stable across PostgreSQL versions.
  scrub <- function(x) {
    x <- x[!grepl("^(CONTEXT|LINE|DETAIL|\\s*\\^)", x)]
    x
  }

  expect_snapshot(
    error = TRUE,
    transform = scrub,
    dbGetQuery(con, "SELECT * FROM no_such_table_579")
  )

  expect_snapshot(
    error = TRUE,
    transform = scrub,
    dbExecute(
      con,
      "DO $$ BEGIN RAISE EXCEPTION 'boom' USING ERRCODE = 'FS002'; END $$;"
    )
  )
})
