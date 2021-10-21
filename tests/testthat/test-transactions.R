context("transactions")

test_that("autocommit", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  local_edition(3)

  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con2)), "a")
})

test_that("commit unnamed transactions", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  expect_fale(postgresIsTransacting(con))
  dbBegin(con)
  expect_true(postgresIsTransacting(con))
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbCommit(con)
  expect_fale(postgresIsTransacting(con))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), c("a", "b"))
})

test_that("rollback unnamed transactions", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbRollback(con)
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "b")
  expect_equal(sort(dbListTables(con2)), "b")
})

test_that("no nested unnamed transactions (commit after error)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  expect_error(dbBegin(con))
  dbCommit(con)

  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")
})

test_that("no nested unnamed transactions (rollback after error)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try(dbRemoveTable(con, "a"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  expect_error(dbBegin(con))
  dbCommit(con)

  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")
})

test_that("named transactions need unnamed transaction", {
  skip_on_cran()
  con <- postgresDefault()
  on.exit(
    {
      dbDisconnect(con)
    },
    add = TRUE
  )

  expect_error(dbBegin(con, name = "tx"))
})

test_that("commit named transactions", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try(dbRemoveTable(con, "a"))
      try(dbRemoveTable(con, "b"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbCommit(con, name = "tx")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbCommit(con)
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), c("a", "b"))
})

test_that("rollback named transactions", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con, name = "tx")
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con)
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "b")
  expect_equal(sort(dbListTables(con2)), "b")
})

test_that("nested named transactions (commit - commit)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      try_silent(dbRemoveTable(con, "c"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbBegin(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con, name = "tx")
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con)
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), c("a", "b"))

  dbCreateTable(con, "c", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b", "c"))
  expect_equal(sort(dbListTables(con2)), c("a", "b", "c"))
})

test_that("nested named transactions (commit - rollback)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      try_silent(dbRemoveTable(con, "c"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbBegin(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con, name = "tx")
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con)
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "c", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "c")
  expect_equal(sort(dbListTables(con2)), "c")
})

test_that("nested named transactions (rollback - commit)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      try_silent(dbRemoveTable(con, "c"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbBegin(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con, name = "tx")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCommit(con)
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")

  dbCreateTable(con, "c", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "c"))
  expect_equal(sort(dbListTables(con2)), c("a", "c"))
})

test_that("nested named transactions (rollback - rollback)", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      try_silent(dbRemoveTable(con, "c"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "tx")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbBegin(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "b", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con, name = "tx2")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con, name = "tx")
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbRollback(con)
  expect_equal(sort(dbListTables(con)), character())
  expect_equal(sort(dbListTables(con2)), character())

  dbCreateTable(con, "c", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "c")
  expect_equal(sort(dbListTables(con2)), "c")
})

test_that("named transactions with keywords", {
  skip_on_cran()
  con <- postgresDefault()
  con2 <- postgresDefault()
  on.exit(
    {
      try_silent(dbRemoveTable(con, "a"))
      try_silent(dbRemoveTable(con, "b"))
      dbDisconnect(con)
      dbDisconnect(con2)
    },
    add = TRUE
  )

  dbBegin(con)
  dbBegin(con, name = "SELECT")
  dbCreateTable(con, "a", data.frame(a = 1))
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbCommit(con, name = "SELECT")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), character())
  dbCommit(con)
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")

  dbBegin(con)
  dbBegin(con, name = "WHERE")
  dbCreateTable(con, "b", data.frame(b = 1))
  expect_equal(sort(dbListTables(con)), c("a", "b"))
  expect_equal(sort(dbListTables(con2)), "a")
  dbRollback(con, name = "WHERE")
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")
  dbRollback(con)
  expect_equal(sort(dbListTables(con)), "a")
  expect_equal(sort(dbListTables(con2)), "a")
})
