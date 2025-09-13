test_that("check_interrupts = TRUE works with queries < 1 second", {
  con <- postgresDefault(check_interrupts = TRUE)
  time <- system.time(
    expect_equal(dbGetQuery(con, "SELECT pg_sleep(0.2), 'foo' AS x")$x, "foo")
  )
  expect_lt(time[["elapsed"]], 0.9)
  dbDisconnect(con)
})

test_that("check_interrupts = TRUE works with queries > 1 second (#244)", {
  con <- postgresDefault(check_interrupts = TRUE)
  time <- system.time(
    expect_equal(dbGetQuery(con, "SELECT pg_sleep(2), 'foo' AS x")$x, "foo")
  )
  expect_gt(time[["elapsed"]], 1.5)
  dbDisconnect(con)
})

test_that("check_interrupts = TRUE interrupts immediately (#336)", {
  skip_if_not(postgresHasDefault())
  skip_if(Sys.getenv("R_COVR") != "")

  session <- callr::r_session$new()

  session$supervise(TRUE)

  session$run(function() {
    library(RPostgres)
    .GlobalEnv$conn <- postgresDefault(check_interrupts = TRUE)
    .GlobalEnv$connPid <- dbGetQuery(
      .GlobalEnv$conn,
      "SELECT pg_backend_pid() AS pid"
    )$pid
    .GlobalEnv$checkConn <- postgresDefault()
    invisible()
  })

  session$call(function() {
    dbGetQuery(.GlobalEnv$conn, "SELECT pg_sleep(10)")
  })

  expect_equal(session$poll_process(500), "timeout")
  session$interrupt()
  # Interrupts are slow on Windows, give ample time
  expect_equal(session$poll_process(2000), "ready")
  session$read()

  queryStatus = session$run(function() {
    dbGetQuery(
      .GlobalEnv$checkConn,
      "SELECT state FROM pg_stat_activity WHERE pid = $1",
      params = .GlobalEnv$connPid
    )
  })
  expect_equal(queryStatus$state, "idle")

  session$close()
})
