# Execute a SQL statement on a database connection

To retrieve results a chunk at a time, use
[`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html),
[`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html), then
[`dbClearResult()`](https://dbi.r-dbi.org/reference/dbClearResult.html).
Alternatively, if you want all the results (and they'll fit in memory)
use [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html)
which sends, fetches and clears for you.

## Usage

``` r
# S4 method for class 'PqResult'
dbBind(res, params, ...)

# S4 method for class 'PqResult'
dbClearResult(res, ...)

# S4 method for class 'PqResult'
dbFetch(res, n = -1, ..., row.names = FALSE)

# S4 method for class 'PqResult'
dbHasCompleted(res, ...)

# S4 method for class 'PqConnection'
dbSendQuery(conn, statement, params = NULL, ..., immediate = FALSE)
```

## Arguments

- res:

  Code a
  [PqResult](https://rpostgres.r-dbi.org/reference/PqResult-class.md)
  produced by
  [`DBI::dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html).

- params:

  A list of query parameters to be substituted into a parameterised
  query. Query parameters are sent as strings, and the correct type is
  imputed by PostgreSQL. If this fails, you can manually cast the
  parameter with e.g. `"$1::bigint"`.

- ...:

  Other arguments needed for compatibility with generic (currently
  ignored).

- n:

  Number of rows to return. If less than zero returns all rows.

- row.names:

  Either `TRUE`, `FALSE`, `NA` or a string.

  If `TRUE`, always translate row names to a column called "row_names".
  If `FALSE`, never translate row names. If `NA`, translate rownames
  only if they're a character vector.

  A string is equivalent to `TRUE`, but allows you to override the
  default name.

  For backward compatibility, `NULL` is equivalent to `FALSE`.

- conn:

  A
  [PqConnection](https://rpostgres.r-dbi.org/reference/PqConnection-class.md)
  created by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html).

- statement:

  An SQL string to execute.

- immediate:

  If `TRUE`, uses the `PGsendQuery()` API instead of `PGprepare()`. This
  allows to pass multiple statements and turns off the ability to pass
  parameters.

## Multiple queries and statements

With `immediate = TRUE`, it is possible to pass multiple queries or
statements, separated by semicolons. For multiple statements, the
resulting value of
[`DBI::dbGetRowsAffected()`](https://dbi.r-dbi.org/reference/dbGetRowsAffected.html)
corresponds to the total number of affected rows. If multiple queries
are used, all queries must return data with the same column names and
types. Queries and statements can be mixed.

## Examples

``` r
library(DBI)
db <- dbConnect(RPostgres::Postgres())
dbWriteTable(db, "usarrests", datasets::USArrests, temporary = TRUE)

# Run query to get results as dataframe
dbGetQuery(db, "SELECT * FROM usarrests LIMIT 3")
#>   Murder Assault UrbanPop Rape
#> 1   13.2     236       58 21.2
#> 2   10.0     263       48 44.5
#> 3    8.1     294       80 31.0

# Send query to pull requests in batches
res <- dbSendQuery(db, "SELECT * FROM usarrests")
dbFetch(res, n = 2)
#>   Murder Assault UrbanPop Rape
#> 1   13.2     236       58 21.2
#> 2   10.0     263       48 44.5
dbFetch(res, n = 2)
#>   Murder Assault UrbanPop Rape
#> 1    8.1     294       80 31.0
#> 2    8.8     190       50 19.5
dbHasCompleted(res)
#> [1] FALSE
dbClearResult(res)

dbRemoveTable(db, "usarrests")

dbDisconnect(db)
```
