context("checkInterrupts")

test_that("check_interrupts = TRUE works with queries > 1 second (#244)", {
  con <- postgresDefault(check_interrupts = TRUE)
  expect_equal(dbGetQuery(con, "SELECT pg_sleep(2), 'foo' AS x")$x, "foo")
  dbDisconnect(con)
})

test_that("check_interrupts = TRUE interrupts immediately (#336)", {
  # For skipping if not available
  dbDisconnect(postgresDefault())

  session <- callr::r_session$new()

  session$run(function() {
    library(RPostgres)
    .GlobalEnv$conn <- postgresDefault(check_interrupts = TRUE)
    invisible()
  })

  session$call(function() {
    tryCatch(
      print(dbGetQuery(.GlobalEnv$conn, "SELECT pg_sleep(2)")),
      error = identity
    )
  })

  session$poll_process(100)
  expect_null(session$read())

  session$interrupt()

  # Should take much less than 1.9 seconds
  time <- system.time(
    expect_equal(session$poll_process(2000), "ready")
  )
  expect_lt(time[["elapsed"]], 1)

  local_edition(3)

  # Should return a proper error message
  out <- session$read()
  out$message <- NULL

  expect_snapshot({
    out
  })
})
