test_that("querying closed connection throws error", {
  db <- postgresDefault()
  dbDisconnect(db)
  expect_error(dbSendQuery(db, "select * from foo"), "bad_weak_ptr")
})

test_that("warn if previous result set is invalidated", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  rs1 <- dbSendQuery(con, "SELECT 1 + 1")

  expect_warning(
    rs2 <- dbSendQuery(con, "SELECT 1 + 1"),
    "Closing open result set, cancelling previous query",
    fixed = TRUE
  )
  expect_false(dbIsValid(rs1))

  dbClearResult(rs2)
})

test_that("no warning if previous result set is closed", {
  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  rs1 <- dbSendQuery(con, "SELECT 1 + 1")
  dbClearResult(rs1)

  expect_warning(rs2 <- dbSendQuery(con, "SELECT 1 + 1"), NA)
  dbClearResult(rs2)
})

test_that("warning if close connection with open results", {
  con <- postgresDefault()

  rs1 <- dbSendQuery(con, "SELECT 1 + 1")

  expect_warning(dbDisconnect(con), "still in use")

  dbClearResult(rs1)
})

test_that("passing other options parameters", {
  con <- postgresDefault(application_name = "apple")
  on.exit(dbDisconnect(con))

  pid <- dbGetInfo(con)$pid
  r <- dbGetQuery(
    con,
    "SELECT application_name FROM pg_stat_activity WHERE pid=$1",
    list(pid)
  )
  expect_identical(r$application_name, "apple")
})

test_that("search_path option exposes schema tables via dbListTables", {
  con <- postgresDefault()
  con2 <- NULL
  schema <- paste0("rpostgres_docs_", as.integer(Sys.getpid()))
  on.exit(
    {
      if (!is.null(con2) && dbIsValid(con2)) {
        dbDisconnect(con2)
      }
      if (dbIsValid(con)) {
        quoted_schema <- as.character(dbQuoteIdentifier(con, schema))
        try(
          dbExecute(con, paste0("DROP SCHEMA IF EXISTS ", quoted_schema, " CASCADE")),
          silent = TRUE
        )
        dbDisconnect(con)
      }
    },
    add = TRUE
  )

  quoted_schema <- as.character(dbQuoteIdentifier(con, schema))
  dbExecute(con, paste0("DROP SCHEMA IF EXISTS ", quoted_schema, " CASCADE"))
  dbExecute(con, paste0("CREATE SCHEMA ", quoted_schema))
  table_name <- "schema_demo"
  dbWriteTable(
    con,
    Id(schema = schema, table = table_name),
    iris[1:3, ],
    overwrite = TRUE
  )

  schema_tables <- dbListObjects(con, Id(schema = schema))
  expect_equal(nrow(schema_tables), 1L)
  expect_false(schema_tables$is_prefix[[1]])
  expect_equal(
    schema_tables$table[[1]],
    Id(schema = schema, table = table_name)
  )

  con2 <- postgresDefault(options = paste0("-c search_path=", schema))
  expect_equal(dbListTables(con2), table_name)
})

test_that("error if passing unkown parameters", {
  skip_on_cran()
  expect_error(
    dbConnect(Postgres(), fruit = "apple"),
    'invalid connection option "fruit"'
  )
})

test_that("NOTICEs are captured as messages", {
  skip_on_cran()

  con <- postgresDefault()
  on.exit(dbDisconnect(con))

  expect_message(
    DBI::dbExecute(
      con,
      "
    DO language plpgsql $$
      BEGIN
        RAISE NOTICE 'hello, world!';
      END
    $$;"
    ),
    "hello, world"
  )
})
