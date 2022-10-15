test_that("special characters work", {
  con <- postgresDefault()

  angstrom <- enc2utf8("\\u00e5")

  dbExecute(con, "CREATE TEMPORARY TABLE test1 (x TEXT)")
  dbExecute(con, "INSERT INTO test1 VALUES ('\\u00e5')")

  expect_equal(dbGetQuery(con, "SELECT * FROM test1")$x, angstrom)
  expect_equal(dbGetQuery(con, "SELECT * FROM test1 WHERE x = '\\u00e5'")$x,
    angstrom)
})


# Not generic enough for DBItest
test_that("JSONB format is recognized", {
  con <- postgresDefault()

  n_json <- dbGetQuery(con, "SELECT count(*) FROM pg_type WHERE typname = 'jsonb' AND typtype = 'b'")[[1]]
  if (as.integer(n_json) == 0) skip("No jsonb type installed")

  jsonb <- '{\"name\": \"mike\"}'

  dbExecute(con, "CREATE TEMPORARY TABLE test2 (data JSONB)")
  dbExecute(con, paste0("INSERT INTO test2(data) values ('", jsonb, "');"))

  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT * FROM test2")$data, structure(jsonb, class = "pq_jsonb")),
    NA
  )

  dbDisconnect(con)
})


test_that("uuid format is recognized", {
  con <- postgresDefault()

  dbExecute(con, "CREATE TEMPORARY TABLE fuutab
    (
    fuu UUID,
    name VARCHAR(255) NOT NULL
    );")

  uuid <- "c44352c0-72bd-11e5-a7f3-0002a5d5c51b"

  dbExecute(con, paste0("INSERT INTO fuutab(fuu, name) values ('", uuid, "', 'bob');"))

  expect_warning(
    expect_equal(dbGetQuery(con, "SELECT * FROM fuutab")$fuu, uuid),
    NA
  )

  dbDisconnect(con)
})

test_that("queries with check_interrupt = TRUE work (#193)", {
  con <- postgresDefault(check_interrupts = TRUE)

  expect_equal(dbGetQuery(con, "SELECT 1")[[1]], 1)

  dbDisconnect(con)
})
