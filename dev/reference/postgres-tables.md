# Convenience functions for reading/writing DBMS tables

[`DBI::dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
is overridden because RPostgres uses placeholders of the form `$1`, `$2`
etc. instead of `?`.

[`DBI::dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
executes several SQL statements that create/overwrite a table and fill
it with values. RPostgres does not use parameterised queries to insert
rows because benchmarks revealed that this was considerably slower than
using a single SQL string.

## Usage

``` r
# S4 method for class 'PqConnection'
dbAppendTable(conn, name, value, copy = NULL, ..., row.names = NULL)

# S4 method for class 'PqConnection,Id'
dbExistsTable(conn, name, ...)

# S4 method for class 'PqConnection,character'
dbExistsTable(conn, name, ...)

# S4 method for class 'PqConnection,Id'
dbListFields(conn, name, ...)

# S4 method for class 'PqConnection,character'
dbListFields(conn, name, ...)

# S4 method for class 'PqConnection'
dbListObjects(conn, prefix = NULL, ...)

# S4 method for class 'PqConnection'
dbListTables(conn, ...)

# S4 method for class 'PqConnection,character'
dbReadTable(conn, name, ..., check.names = TRUE, row.names = FALSE)

# S4 method for class 'PqConnection,character'
dbRemoveTable(conn, name, ..., temporary = FALSE, fail_if_missing = TRUE)

# S4 method for class 'PqConnection,character,data.frame'
dbWriteTable(
  conn,
  name,
  value,
  ...,
  row.names = FALSE,
  overwrite = FALSE,
  append = FALSE,
  field.types = NULL,
  temporary = FALSE,
  copy = NULL
)

# S4 method for class 'PqConnection'
sqlData(con, value, row.names = FALSE, ...)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/dev/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- name:

  a character string specifying a table name. Names will be
  automatically quoted so you can use any sequence of characters, not
  just any valid bare table name. Alternatively, pass a name quoted with
  [`DBI::dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html),
  an [`Id()`](https://dbi.r-dbi.org/reference/Id.html) object, or a
  string escaped with
  [`DBI::SQL()`](https://dbi.r-dbi.org/reference/SQL.html).

- value:

  A data.frame to write to the database.

- copy:

  If `TRUE`, serializes the data frame to a single string and uses
  `COPY name FROM stdin`. This is fast, but not supported by all
  postgres servers (e.g. Amazon's Redshift). If `FALSE`, generates a
  single SQL string. This is slower, but always supported. The default
  maps to `TRUE` on connections established via
  [`Postgres()`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  and to `FALSE` on connections established via
  [`Redshift()`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md).

- ...:

  Ignored.

- row.names:

  Either `TRUE`, `FALSE`, `NA` or a string.

  If `TRUE`, always translate row names to a column called "row_names".
  If `FALSE`, never translate row names. If `NA`, translate rownames
  only if they're a character vector.

  A string is equivalent to `TRUE`, but allows you to override the
  default name.

  For backward compatibility, `NULL` is equivalent to `FALSE`.

- prefix:

  A fully qualified path in the database's namespace, or `NULL`. This
  argument will be processed with
  [`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html).
  If given the method will return all objects accessible through this
  prefix.

- check.names:

  If `TRUE`, the default, column names will be converted to valid R
  identifiers.

- temporary:

  If `TRUE`, only temporary tables are considered.

- fail_if_missing:

  If `FALSE`,
  [`dbRemoveTable()`](https://dbi.r-dbi.org/reference/dbRemoveTable.html)
  succeeds if the table doesn't exist.

- overwrite:

  a logical specifying whether to overwrite an existing table or not.
  Its default is `FALSE`.

- append:

  a logical specifying whether to append to an existing table in the
  DBMS. Its default is `FALSE`.

- field.types:

  character vector of named SQL field types where the names are the
  names of new table's columns. If missing, types are inferred with
  [`DBI::dbDataType()`](https://dbi.r-dbi.org/reference/dbDataType.html)).
  The types can only be specified with `append = FALSE`.

- con:

  A database connection.

## Schemas, catalogs, tablespaces

Pass an identifier created with
[`Id()`](https://dbi.r-dbi.org/reference/Id.html) as the `name` argument
to specify the schema or catalog, e.g.
`name = Id(catalog = "my_catalog", schema = "my_schema", table = "my_table")`
. To specify the tablespace, use
`dbExecute(conn, "SET default_tablespace TO my_tablespace")` before
creating the table.

## Examples

``` r
library(DBI)
con <- dbConnect(RPostgres::Postgres())
dbListTables(con)
#> character(0)
dbWriteTable(con, "mtcars", mtcars, temporary = TRUE)
dbReadTable(con, "mtcars")
#>     mpg cyl  disp  hp drat    wt  qsec vs am gear carb
#> 1  21.0   6 160.0 110 3.90 2.620 16.46  0  1    4    4
#> 2  21.0   6 160.0 110 3.90 2.875 17.02  0  1    4    4
#> 3  22.8   4 108.0  93 3.85 2.320 18.61  1  1    4    1
#> 4  21.4   6 258.0 110 3.08 3.215 19.44  1  0    3    1
#> 5  18.7   8 360.0 175 3.15 3.440 17.02  0  0    3    2
#> 6  18.1   6 225.0 105 2.76 3.460 20.22  1  0    3    1
#> 7  14.3   8 360.0 245 3.21 3.570 15.84  0  0    3    4
#> 8  24.4   4 146.7  62 3.69 3.190 20.00  1  0    4    2
#> 9  22.8   4 140.8  95 3.92 3.150 22.90  1  0    4    2
#> 10 19.2   6 167.6 123 3.92 3.440 18.30  1  0    4    4
#> 11 17.8   6 167.6 123 3.92 3.440 18.90  1  0    4    4
#> 12 16.4   8 275.8 180 3.07 4.070 17.40  0  0    3    3
#> 13 17.3   8 275.8 180 3.07 3.730 17.60  0  0    3    3
#> 14 15.2   8 275.8 180 3.07 3.780 18.00  0  0    3    3
#> 15 10.4   8 472.0 205 2.93 5.250 17.98  0  0    3    4
#> 16 10.4   8 460.0 215 3.00 5.424 17.82  0  0    3    4
#> 17 14.7   8 440.0 230 3.23 5.345 17.42  0  0    3    4
#> 18 32.4   4  78.7  66 4.08 2.200 19.47  1  1    4    1
#> 19 30.4   4  75.7  52 4.93 1.615 18.52  1  1    4    2
#> 20 33.9   4  71.1  65 4.22 1.835 19.90  1  1    4    1
#> 21 21.5   4 120.1  97 3.70 2.465 20.01  1  0    3    1
#> 22 15.5   8 318.0 150 2.76 3.520 16.87  0  0    3    2
#> 23 15.2   8 304.0 150 3.15 3.435 17.30  0  0    3    2
#> 24 13.3   8 350.0 245 3.73 3.840 15.41  0  0    3    4
#> 25 19.2   8 400.0 175 3.08 3.845 17.05  0  0    3    2
#> 26 27.3   4  79.0  66 4.08 1.935 18.90  1  1    4    1
#> 27 26.0   4 120.3  91 4.43 2.140 16.70  0  1    5    2
#> 28 30.4   4  95.1 113 3.77 1.513 16.90  1  1    5    2
#> 29 15.8   8 351.0 264 4.22 3.170 14.50  0  1    5    4
#> 30 19.7   6 145.0 175 3.62 2.770 15.50  0  1    5    6
#> 31 15.0   8 301.0 335 3.54 3.570 14.60  0  1    5    8
#> 32 21.4   4 121.0 109 4.11 2.780 18.60  1  1    4    2

dbListTables(con)
#> [1] "mtcars"
dbExistsTable(con, "mtcars")
#> [1] TRUE

# A zero row data frame just creates a table definition.
dbWriteTable(con, "mtcars2", mtcars[0, ], temporary = TRUE)
dbReadTable(con, "mtcars2")
#>  [1] mpg  cyl  disp hp   drat wt   qsec vs   am   gear carb
#> <0 rows> (or 0-length row.names)

dbDisconnect(con)
```
