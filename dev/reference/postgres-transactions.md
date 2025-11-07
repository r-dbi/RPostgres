# Transaction management.

[`dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html) starts
a transaction.
[`dbCommit()`](https://dbi.r-dbi.org/reference/transactions.html) and
[`dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html) end
the transaction by either committing or rolling back the changes.

## Usage

``` r
# S4 method for class 'PqConnection'
dbBegin(conn, ..., name = NULL)

# S4 method for class 'PqConnection'
dbCommit(conn, ..., name = NULL)

# S4 method for class 'PqConnection'
dbRollback(conn, ..., name = NULL)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/dev/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- ...:

  Unused, for extensibility.

- name:

  If provided, uses the `SAVEPOINT` SQL syntax to establish, remove
  (commit) or undo a ßsavepoint.

## Value

A boolean, indicating success or failure.

## Examples

``` r
library(DBI)
con <- dbConnect(RPostgres::Postgres())
dbWriteTable(con, "USarrests", datasets::USArrests, temporary = TRUE)
dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#>   count
#> 1    50

dbBegin(con)
dbExecute(con, 'DELETE from "USarrests" WHERE "Murder" > 1')
#> [1] 49
dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#>   count
#> 1     1
dbRollback(con)

# Rolling back changes leads to original count
dbGetQuery(con, 'SELECT count(*) from "USarrests"')
#>   count
#> 1    50

dbRemoveTable(con, "USarrests")
dbDisconnect(con)
```
