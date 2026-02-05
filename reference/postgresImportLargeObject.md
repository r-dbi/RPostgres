# Imports a large object from file

Returns an object identifier (Oid) for the imported large object. This
function must be called within a transaction.

## Usage

``` r
postgresImportLargeObject(conn, filepath = NULL, oid = 0)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- filepath:

  a path to the large object to import

- oid:

  the oid to write to. Defaults to 0 which assigns an unused oid

## Value

the identifier of the large object, an integer

## Examples

``` r
if (FALSE) { # \dontrun{
con <- postgresDefault()
filepath <- 'your_image.png'
dbWithTransaction(con, {
  oid <- postgresImportLargeObject(con, filepath)
})
} # }
```
