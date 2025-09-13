test_that("quoting string", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, "Robert'); DROP TABLE Students;--")
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert\'); DROP TABLE Students;--"')
})

test_that("quoting SQL", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, SQL("Robert'); DROP TABLE Students;--"))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), "Robert'); DROP TABLE Students;--")
})

test_that("quoting Id, table", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id(table = 'Students;--'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Students;--"')
})

test_that("quoting Id, table, unnamed", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id('Students;--'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Students;--"')
})

test_that("quoting Id, schema", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id(schema = 'Robert'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert"')
})

test_that("quoting Id, schema, unnamed", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id('Robert'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert"')
})

test_that("quoting Id, fully-qualified table", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id(schema = 'Robert', table = 'Students;--'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert"."Students;--"')
})

test_that("quoting Id, fully-qualified column, #263", {
  con <- postgresDefault()

  quoted <-
    dbQuoteIdentifier(
      con,
      Id(schema = "Robert", table = "Students;--", column = "dormitory")
    )
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert"."Students;--"."dormitory"')
})

test_that("quoting Id, column, unordered", {
  con <- postgresDefault()

  quoted <-
    dbQuoteIdentifier(con, Id(column = "dormitory", table = 'Students;--'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Students;--"."dormitory"')
})

test_that("quoting Id, fully-qualified column, unnamed", {
  con <- postgresDefault()

  quoted <-
    dbQuoteIdentifier(con, Id('Robert', 'Students;--', "dormitory"))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted), '"Robert"."Students;--"."dormitory"')
})

test_that("unquoting identifier - SQL with quotes", {
  con <- postgresDefault()

  expect_equal(
    dbUnquoteIdentifier(con, SQL('"Students;--"')),
    list(Id(table = 'Students;--'))
  )

  expect_equal(
    dbUnquoteIdentifier(con, SQL('"Robert"."Students;--"')),
    list(Id(schema = 'Robert', table = 'Students;--'))
  )

  expect_equal(
    dbUnquoteIdentifier(con, SQL('"Rob""ert"."Students;--"')),
    list(Id(schema = 'Rob"ert', table = 'Students;--'))
  )

  expect_equal(
    dbUnquoteIdentifier(con, SQL('"Rob.ert"."Students;--"')),
    list(Id(schema = 'Rob.ert', table = 'Students;--'))
  )

  expect_error(
    dbUnquoteIdentifier(con, SQL('"Robert."Students"')),
    "^Can't unquote"
  )
})

test_that("unquoting identifier - SQL without quotes", {
  con <- postgresDefault()

  expect_equal(
    dbUnquoteIdentifier(con, SQL('Students')),
    list(Id(table = 'Students'))
  )

  expect_equal(
    dbUnquoteIdentifier(con, SQL('Robert.Students')),
    list(Id(schema = 'Robert', table = 'Students'))
  )

  expect_error(
    dbUnquoteIdentifier(con, SQL('Rob""ert.Students')),
    "^Can't unquote"
  )
})

test_that("unquoting identifier - Id", {
  con <- postgresDefault()

  expect_equal(
    dbUnquoteIdentifier(con, Id(schema = 'Robert', table = 'Students;--')),
    list(Id(schema = 'Robert', table = 'Students;--'))
  )
})

test_that("quoting text NULL (#393)", {
  con <- postgresDefault()

  dbExecute(con, "CREATE TEMPORARY TABLE null_text (col jsonb)")
  on.exit(dbExecute(con, "DROP TABLE null_text"))

  json <- c("{}", NA)
  values_expr <- paste(
    paste0("(", dbQuoteLiteral(con, json), ")"),
    collapse = ", "
  )
  stmt <- paste0("INSERT INTO null_text (col) VALUES ", values_expr)

  dbExecute(con, stmt)
  expect_equal(
    dbReadTable(con, "null_text")$col,
    structure(c("{}", NA), class = "pq_jsonb")
  )
})
