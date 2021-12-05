context("checkInterrupts")

test_that("check_interrupts = TRUE works with queries < 1 second (#244)", {
  con <- postgresDefault(check_interrupts = TRUE)
  time <- system.time(
    expect_equal(dbGetQuery(con, "SELECT pg_sleep(0.2), 'foo' AS x")$x, "foo")
  )
  expect_lt(time[["elapsed"]], 0.9)
  dbDisconnect(con)
})

test_that("check_interrupts = TRUE interrupts immediately (#336)", {
  skip_if_not(postgresHasDefault())
  skip_if(Sys.getenv("R_COVR") != "")

  # https://github.com/r-lib/processx/issues/319
  skip_on_os("windows")

  session <- callr::r_session$new()

  session$supervise(TRUE)

  session$run(function() {
    library(RPostgres)
    .GlobalEnv$conn <- postgresDefault(check_interrupts = TRUE)
    invisible()
  })

  session$call(function() {
    dbGetQuery(.GlobalEnv$conn, "SELECT pg_sleep(3)")
  })

  expect_equal(session$poll_process(500), "timeout")
  session$interrupt()
  expect_equal(session$poll_process(500), "ready")

  # Tests for error behavior are brittle

  session$close()
})
