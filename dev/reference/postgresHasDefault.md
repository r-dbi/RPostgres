# Check if default database is available.

RPostgres examples and tests connect to a default database via
`dbConnect(`[`Postgres()`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)`)`.
This function checks if that database is available, and if not, displays
an informative message.

`postgresDefault()` works similarly but returns a connection on success
and throws a testthat skip condition on failure, making it suitable for
use in tests.

## Usage

``` r
postgresHasDefault(...)

postgresDefault(...)
```

## Arguments

- ...:

  Additional arguments passed on to
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

## Examples

``` r
if (postgresHasDefault()) {
  db <- postgresDefault()
  print(dbListTables(db))
  dbDisconnect(db)
} else {
  message("No database connection.")
}
#> character(0)
```
