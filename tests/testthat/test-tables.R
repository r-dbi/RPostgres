context("Convenience Functions")

test_that("dbWriteTable and dbRemoveTable", {

  con <- dbConnect(RPostgres::Postgres())
  expect_true(dbWriteTable(con, "mtcars", mtcars[1:10, ]))
  expect_true(all(dbReadTable(con, "mtcars") == mtcars[1:10, ]))


  expect_error(
    dbWriteTable(con, "mtcars2", mtcars[20:25, ], append = TRUE, overwrite = TRUE)
    ,'cannot both be TRUE'
  )


  expect_error(
    dbWriteTable(con, "mtcars", mtcars[1:10, ], append = FALSE, overwrite = FALSE)
    ,'exists in database'
  )


  expect_true(dbRemoveTable(con, "mtcars"))
  expect_error(dbReadTable(con, "mtcars"), 'does not exist')

})

test_that("dbListTables", {

  con <- dbConnect(RPostgres::Postgres())
  Tables1 <- dbListTables(con)

  Tables2 <- DBI::dbGetQuery(con,
    "SELECT tablename
     FROM pg_tables
     WHERE schemaname !='information_schema'
        AND schemaname !='pg_catalog'")

  expect_equal(Tables1, Tables2[[1]])

})



test_that("dbExistsTable", {

  con <- dbConnect(RPostgres::Postgres())

  dbWriteTable(con, "cars", cars[1:10, ])
  expect_true(dbExistsTable(con, 'cars'))

  dbRemoveTable(con, "cars")

})


