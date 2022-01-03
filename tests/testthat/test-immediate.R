test_that("two statements", {
  conn1 <- postgresDefault()
  on.exit(dbDisconnect(conn1))

  sql <- "
DO
$$
BEGIN
  RAISE NOTICE 'message_one';
END
$$
;
DO
$$
BEGIN
  RAISE NOTICE 'message_two';
END
$$
;
"

  local_edition(3)

  expect_message(
    expect_message(
      dbExecute(conn1, sql, immediate = TRUE),
      "message_one"
    ),
    "message_two"
  )
})

test_that("two statements with dbGetRowsAffected()", {
  conn1 <- postgresDefault()
  on.exit(dbDisconnect(conn1))

  dbWriteTable(conn1, "test", data.frame(a = 1:9), temporary = TRUE)

  sql <- "DELETE FROM TEST WHERE a < 3; DELETE FROM TEST WHERE a < 6"
  expect_equal(dbExecute(conn1, sql, immediate = TRUE), 5)

  expect_equal(nrow(dbReadTable(conn1, "test")), 4)
})

test_that("two queries", {
  conn1 <- postgresDefault()
  on.exit(dbDisconnect(conn1))

  sql <- "SELECT 1 AS a UNION ALL SELECT 2 AS a; SELECT 3 AS a"
  expect_equal(
    dbGetQuery(conn1, sql, immediate = TRUE),
    data.frame(a = 1:3)
  )

  sql <- "SELECT 1 AS a, 2 AS b UNION ALL SELECT 2 AS a, 3 AS b; SELECT 3 AS b"
  expect_error(dbGetQuery(conn1, sql, immediate = TRUE), "names")

  sql <- "SELECT 1 AS a; SELECT '2' AS a"
  expect_error(dbGetQuery(conn1, sql, immediate = TRUE), "types")
})

test_that("query and statement", {
  conn1 <- postgresDefault()
  on.exit(dbDisconnect(conn1))

  sql <- "
SELECT 1 AS a;
DO
$$
BEGIN
  RAISE NOTICE 'message_one';
END
$$
"

  expect_message(
    expect_equal(
      dbGetQuery(conn1, sql, immediate = TRUE),
      data.frame(a = 1L)
    ),
    "message_one"
  )
})

test_that("statement and query", {
  conn1 <- postgresDefault()
  on.exit(dbDisconnect(conn1))

  sql <- "
DO
$$
BEGIN
  RAISE NOTICE 'message_one';
END
$$;
SELECT 1 AS a
"

  expect_message(
    expect_equal(
      dbGetQuery(conn1, sql, immediate = TRUE),
      data.frame(a = 1L)
    ),
    "message_one"
  )
})

test_that("immediate with interrupts after notice", {
  skip_if_not(postgresHasDefault())
  skip_if(Sys.getenv("R_COVR") != "")

  session <- callr::r_session$new()
  session$supervise(TRUE)
  session$run(function() {
    library(RPostgres)
    .GlobalEnv$conn1 <- postgresDefault(check_interrupts = TRUE)
    invisible()
  })

  session$call(function() {
    sql <- "
DO
$$
BEGIN
  RAISE NOTICE 'message_one';
END
$$
;
SELECT pg_sleep(10);
DO
$$
BEGIN
  RAISE NOTICE 'message_two';
END
$$
;
"

    dbGetQuery(.GlobalEnv$conn1, sql, immediate = TRUE)
  })

  expect_equal(session$poll_process(500), "timeout")
  session$interrupt()
  # Interrupts are slow on Windows, give ample time
  expect_equal(session$poll_process(2000), "ready")

  # Tests for error behavior are brittle

  session$close()
})


test_that("immediate with interrupts before notice", {
  skip_if_not(postgresHasDefault())
  skip_if(Sys.getenv("R_COVR") != "")

  session <- callr::r_session$new()
  session$supervise(TRUE)
  session$run(function() {
    library(RPostgres)
    .GlobalEnv$conn1 <- postgresDefault(check_interrupts = TRUE)
    invisible()
  })

  session$call(function() {
    sql <- "
SELECT pg_sleep(10);
DO
$$
BEGIN
  RAISE NOTICE 'message_one';
END
$$
;
DO
$$
BEGIN
  RAISE NOTICE 'message_two';
END
$$
;
"
    dbGetQuery(.GlobalEnv$conn1, sql, immediate = TRUE)
  })

  expect_equal(session$poll_process(500), "timeout")
  session$interrupt()
  # Interrupts are slow on Windows, give ample time
  expect_equal(session$poll_process(2000), "ready")

  # Tests for error behavior are brittle

  session$close()
})

test_that("immediate queries after COPY (#382)", {
  con <- postgresDefault()

  dbCreateTable(con, "test", data.frame(a = integer()), temporary = TRUE)
  dbAppendTable(con, "test", data.frame(a = 1:3), copy = TRUE)
  expect_error(dbExecute(con, "DROP TABLE pg_temp.test", immediate = TRUE), NA)
})
