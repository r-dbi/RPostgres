if (postgresHasDefault()) {
  with_database_connection(con = postgresDefault(system_catalogs = TRUE), {

    skip_if(
      is(con, "RedshiftConnection"),
      "Redshift doesn't expose system catalogs"
    )
    skip_if_not(
      dbExistsTable(con, Id(schema = "pg_catalog", table = "pg_class")),
      "`pg_catalog`.`pg_class` not available"
    )

    test_that("Materialized View is listed", {
      with_matview(con, "matview1", "SELECT 1 AS col1", {

        expect_true(dbExistsTable(con, "matview1"))
        expect_true("matview1" %in% dbListTables(con))

        objects <- dbListObjects(con)
        quoted_tables <-
          vapply(
            objects$table,
            dbQuoteIdentifier,
            conn = con,
            character(1)
          )
        expect_true(dbQuoteIdentifier(con, "matview1") %in% quoted_tables)

        expect_true("col1" %in% dbListFields(con, "matview1"))
      })
    })

    test_that("Materialized View in custom schema is listed", {
      with_schema(con, "matschema1", {
        matview_id <- Id(schema = "matschema1", table = "matview1")
        matview_chr <- "matschema1.matview1"

        with_matview(con, matview_chr, "SELECT 1 AS col1", {

          expect_true(dbExistsTable(con, matview_id))

          objects <- dbListObjects(con, prefix = Id(schema = "matschema1"))
          quoted_tables <-
            vapply(
              objects$table,
              dbQuoteIdentifier,
              conn = con,
              character(1)
            )
          expect_true(dbQuoteIdentifier(con, matview_id) %in% quoted_tables)

          expect_true("col1" %in% dbListFields(con, matview_id))
        })
      })
    })
  })
}
