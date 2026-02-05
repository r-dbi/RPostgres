# Return whether a transaction is ongoing

Detect whether the transaction is active for the given connection. A
transaction might be started with
[`DBI::dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html) or
wrapped within
[`DBI::dbWithTransaction()`](https://dbi.r-dbi.org/reference/dbWithTransaction.html).

## Usage

``` r
postgresIsTransacting(conn)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

## Value

A boolean, indicating if a transaction is ongoing.
