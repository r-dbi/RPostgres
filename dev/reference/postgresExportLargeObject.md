# Exports a large object to file

Exports a large object from the database to a file on disk. This
function uses PostgreSQL's `lo_export()` function which efficiently
streams the data directly to disk without loading it into memory, making
it suitable for very large objects (GB+) that would cause memory issues
with `lo_get()`. This function must be called within a transaction.

## Usage

``` r
postgresExportLargeObject(conn, oid, filepath)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/dev/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- oid:

  the object identifier (Oid) of the large object to export

- filepath:

  a path where the large object should be exported

## Value

invisible NULL on success, or stops with an error

## Examples

``` r
if (FALSE) { # \dontrun{
con <- postgresDefault()
filepath <- 'your_image.png'
dbWithTransaction(con, {
  oid <- postgresImportLargeObject(con, filepath)
})
# Later, export the large object back to a file
dbWithTransaction(con, {
  postgresExportLargeObject(con, oid, 'exported_image.png')
})
} # }
```
