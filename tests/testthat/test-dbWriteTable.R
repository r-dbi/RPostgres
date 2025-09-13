if (postgresHasDefault()) {
  with_database_connection({
    describe("Writing to the database", {
      test_that("writing to a database table is successful", {
        with_table(con, "beaver2", {
          dbWriteTable(con, "beaver2", beaver2, temporary = TRUE)
          expect_equal(dbReadTable(con, "beaver2"), beaver2)
        })
      })

      test_that("writing to a database table with character features is successful", {
        with_table(con, "iris", {
          iris2 <- transform(iris, Species = as.character(Species))
          dbWriteTable(con, "iris", iris2, temporary = TRUE)
          expect_equal(dbReadTable(con, "iris"), iris2)
        })
      })
    })

    describe("Appending to the database", {
      test_that("append to a database table is successful", {
        with_table(con, "beaver2", {
          dbWriteTable(con, "beaver2", beaver2, temporary = TRUE)
          dbWriteTable(con, "beaver2", beaver2, append = TRUE, temporary = TRUE)
          expect_equal(dbReadTable(con, "beaver2"), rbind(beaver2, beaver2))
        })
      })

      test_that("append to a database table with character features is successful", {
        with_table(con, "iris", {
          iris2 <- transform(iris, Species = as.character(Species))
          dbWriteTable(con, "iris", iris2, temporary = TRUE)
          dbWriteTable(con, "iris", iris2, append = TRUE, temporary = TRUE)
          expect_equal(dbReadTable(con, "iris"), rbind(iris2, iris2))
        })
      })
    })

    describe("Usage of the field.types argument", {
      test_that("New table creation respects the field.types argument", {
        with_table(con, "iris", {
          iris2 <- transform(
            iris,
            Petal.Width = as.integer(Petal.Width),
            Species = as.character(Species)
          )
          field.types <- c(
            "real",
            "double precision",
            "numeric",
            "bigint",
            "text"
          )
          names(field.types) <- names(iris2)

          dbWriteTable(
            con,
            "iris",
            iris2,
            field.types = field.types,
            temporary = TRUE
          )

          iris3 <- transform(
            iris2,
            Petal.Width = bit64::as.integer64(Petal.Width)
          )
          expect_equal(dbReadTable(con, "iris"), iris3)

          # http://stackoverflow.com/questions/2146705/select-datatype-of-the-field-in-postgres
          types <- DBI::dbGetQuery(
            con,
            paste(
              "select column_name, data_type from information_schema.columns ",
              "where table_name = 'iris'"
            )
          )
          expected <- data.frame(
            column_name = colnames(iris2),
            data_type = field.types,
            stringsAsFactors = FALSE
          )
          types <- without_rownames(types[order(types$column_name), ])
          expected <- without_rownames(expected[order(expected$column_name), ])

          expect_equal(types, expected)
        })
      })

      test_that("Appending fails when using the field.types argument", {
        with_table(con, "iris", {
          iris2 <- transform(
            iris,
            Petal.Width = as.integer(Petal.Width),
            Species = as.character(Species)
          )
          field.types <- c(
            "real",
            "double precision",
            "numeric",
            "bigint",
            "text"
          )
          names(field.types) <- names(iris2)

          dbWriteTable(
            con,
            "iris",
            iris2,
            field.types = field.types,
            temporary = TRUE
          )
          expect_error(
            dbWriteTable(
              con,
              "iris",
              iris2,
              field.types = field.types,
              append = TRUE,
              temporary = TRUE
            ),
            "field[.]types"
          )
        })
      })
    })

    describe("Writing to the database with possible numeric precision issues", {
      # reference value
      value <- data.frame(
        x = -0.000064925595060641,
        y = -0.00006492559506064059
      )
      test_that("dbWriteTable(copy = F)", {
        with_table(con, "xy", {
          dbWriteTable(con, name = "xy", value = value, copy = F)
          expect_equal(dbGetQuery(con, "SELECT * FROM xy"), value)
        })
      })

      test_that("dbWriteTable(append = T, copy = F)", {
        with_table(con, "xy", {
          dbExecute(
            con,
            "CREATE TEMPORARY TABLE xy ( x numeric NOT NULL, y numeric NOT NULL);"
          )
          dbWriteTable(con, name = "xy", value = value, append = T, copy = F)
          expect_equal(dbGetQuery(con, "SELECT * FROM xy"), value)
        })
      })

      test_that("dbWriteTable(append = T, copy = T)", {
        with_table(con, "xy", {
          dbExecute(
            con,
            "CREATE TEMPORARY TABLE xy ( x numeric NOT NULL, y numeric NOT NULL);"
          )
          dbWriteTable(con, name = "xy", value = value, append = T, copy = T)
          expect_equal(dbGetQuery(con, "SELECT * FROM xy"), value)
        })
      })

      test_that("dbWriteTable(append = F, copy = T, field.types=NUMERIC)", {
        with_table(con, "xy", {
          dbWriteTable(
            con,
            name = "xy",
            value = value,
            overwrite = F,
            append = F,
            copy = T,
            field.types = c(x = "NUMERIC", y = "NUMERIC")
          )
          expect_equal(dbGetQuery(con, "SELECT * FROM xy"), value)
        })
      })
    })

    describe("Inf values", {
      test_that("Inf values come back correctly", {
        skip_on_cran()

        res <- dbGetQuery(
          con,
          "SELECT '-inf'::float8 AS a, '+inf'::float8 AS b, 'NaN'::float8 AS c, NULL::float8 AS d"
        )
        expect_equal(res$a, -Inf)
        expect_equal(res$b, Inf)
        expect_true(is.nan(res$c))
        expect_true(is.na(res$d))
        expect_false(is.nan(res$d))
      })

      test_that("Inf values are roundtripped correctly", {
        skip_on_cran()

        with_table(con, "xy", {
          data <- data.frame(
            column_1 = c("A", "B", "C"),
            column_2 = c(1, Inf, 3),
            stringsAsFactors = FALSE
          )
          dbWriteTable(con, "xy", data, row.names = FALSE)

          data_out <- dbReadTable(con, "xy")
          expect_equal(data, data_out)
        })
      })
    })

    describe("Name clashes", {
      test_that("Can write to temporary table if permanent table exists (#402)", {
        skip_on_cran()

        dbWriteTable(con, "my_name_clash", data.frame(a = 1), overwrite = TRUE)
        expect_equal(dbReadTable(con, "my_name_clash"), data.frame(a = 1))

        dbWriteTable(
          con,
          "my_name_clash",
          data.frame(b = 2),
          overwrite = TRUE,
          temporary = TRUE
        )
        expect_equal(dbReadTable(con, "my_name_clash"), data.frame(b = 2))

        dbRemoveTable(con, "my_name_clash", temporary = TRUE)
        expect_equal(dbReadTable(con, "my_name_clash"), data.frame(a = 1))

        dbRemoveTable(con, "my_name_clash")
        dbDisconnect(con)
      })
    })
  })
}
