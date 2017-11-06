context("dbWriteTable")

with_database_connection({
  describe("Writing to the database", {
    test_that("writing to a database table is successful", {
      with_table(con, "beaver2", {
        dbWriteTable(con, "beaver2", beaver2)
        expect_equal(dbReadTable(con, "beaver2"), beaver2)
      })
    })

    test_that("writing to a database table with character features is successful", {
      with_table(con, "iris", {
        iris2 <- transform(iris, Species = as.character(Species))
        dbWriteTable(con, "iris", iris2)
        expect_equal(dbReadTable(con, "iris"), iris2)
      })
    })
  })

  describe("Appending to the database", {
    test_that("append to a database table is successful", {
      with_table(con, "beaver2", {
        dbWriteTable(con, "beaver2", beaver2)
        dbWriteTable(con, "beaver2", beaver2, append = TRUE)
        expect_equal(dbReadTable(con, "beaver2"), rbind(beaver2, beaver2))
      })
    })

    test_that("append to a database table with character features is successful", {
      with_table(con, "iris", {
        iris2 <- transform(iris, Species = as.character(Species))
        dbWriteTable(con, "iris", iris2)
        dbWriteTable(con, "iris", iris2, append = TRUE)
        expect_equal(dbReadTable(con, "iris"), rbind(iris2, iris2))
      })
    })
  })

  describe("Usage of the field.types argument", {
    test_that("New table creation respects the field.types argument", {
      with_table(con, "iris", {
        iris2       <- transform(iris, Petal.Width = as.integer(Petal.Width),
                                 Species = as.character(Species))
        field.types <- c("real", "double precision", "numeric", "bigint", "text")

        dbWriteTable(con, "iris", iris2, field.types = field.types)
        expect_equal(dbReadTable(con, "iris"), iris2)

        # http://stackoverflow.com/questions/2146705/select-datatype-of-the-field-in-postgres
        types <- DBI::dbGetQuery(con,
          paste("select column_name, data_type from information_schema.columns ",
                "where table_name = 'iris'"))
        expected <- data.frame(column_name = colnames(iris2),
                               data_type = field.types, stringsAsFactors = FALSE)
        types    <- without_rownames(types[order(types$column_name), ])
        expected <- without_rownames(expected[order(expected$column_name), ])

        expect_equal(types, expected)
      })
    })

    test_that("Appending still works when using the field.types argument", {
      with_table(con, "iris", {
        iris2       <- transform(iris, Petal.Width = as.integer(Petal.Width),
                                 Species = as.character(Species))
        field.types <- c("real", "double precision", "numeric", "bigint", "text")

        dbWriteTable(con, "iris", iris2, field.types = field.types)
        dbWriteTable(con, "iris", iris2, field.types = field.types, append = TRUE)
        expect_equal(dbReadTable(con, "iris"), rbind(iris2, iris2))

        # http://stackoverflow.com/questions/2146705/select-datatype-of-the-field-in-postgres
        types <- DBI::dbGetQuery(con,
          paste("select column_name, data_type from information_schema.columns ",
                "where table_name = 'iris'"))
        expected <- data.frame(column_name = colnames(iris2),
                               data_type = field.types, stringsAsFactors = FALSE)
        types    <- without_rownames(types[order(types$column_name), ])
        expected <- without_rownames(expected[order(expected$column_name), ])

        expect_equal(types, expected)
      })
    })
  })
})

