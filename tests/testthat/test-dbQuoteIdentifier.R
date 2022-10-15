test_that("quoting string", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, "Robert'); DROP TABLE Students;--")
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted),
    '"Robert\'); DROP TABLE Students;--"')
})

test_that("quoting SQL", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, SQL("Robert'); DROP TABLE Students;--"))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted),
    "Robert'); DROP TABLE Students;--")
})

test_that("quoting Id", {
  con <- postgresDefault()

  quoted <- dbQuoteIdentifier(con, Id(schema = 'Robert', table = 'Students;--'))
  expect_s4_class(quoted, 'SQL')
  expect_equal(as.character(quoted),
    '"Robert"."Students;--"')
})

test_that("unquoting identifier - SQL with quotes", {
  con <- postgresDefault()

  expect_equal(dbUnquoteIdentifier(con, SQL('"Students;--"')),
    list(Id(table = 'Students;--')))

  expect_equal(dbUnquoteIdentifier(con, SQL('"Robert"."Students;--"')),
    list(Id(schema = 'Robert', table = 'Students;--')))

  expect_equal(dbUnquoteIdentifier(con, SQL('"Rob""ert"."Students;--"')),
    list(Id(schema = 'Rob"ert', table = 'Students;--')))

  expect_equal(dbUnquoteIdentifier(con, SQL('"Rob.ert"."Students;--"')),
    list(Id(schema = 'Rob.ert',  table = 'Students;--')))

  expect_error(dbUnquoteIdentifier(con, SQL('"Robert."Students"')),
    "^Can't unquote")
})

test_that("unquoting identifier - SQL without quotes", {
  con <- postgresDefault()

  expect_equal(dbUnquoteIdentifier(con, SQL('Students')),
    list(Id(table = 'Students')))

  expect_equal(dbUnquoteIdentifier(con, SQL('Robert.Students')),
    list(Id(schema = 'Robert', table = 'Students')))

  expect_error(dbUnquoteIdentifier(con, SQL('Rob""ert.Students')),
    "^Can't unquote")
})

test_that("unquoting identifier - Id", {
  con <- postgresDefault()

  expect_equal(dbUnquoteIdentifier(con,
    Id(schema = 'Robert', table = 'Students;--')),
  list(Id(schema = 'Robert', table = 'Students;--')))
})
