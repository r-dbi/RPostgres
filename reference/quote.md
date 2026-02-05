# Quote postgres strings, identifiers, and literals

If an object of class [Id](https://dbi.r-dbi.org/reference/Id.html) is
used for
[`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html),
it needs at most one `table` component and at most one `schema`
component.

## Usage

``` r
# S4 method for class 'PqConnection,Id'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'PqConnection,SQL'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'PqConnection,character'
dbQuoteIdentifier(conn, x, ...)

# S4 method for class 'PqConnection'
dbQuoteLiteral(conn, x, ...)

# S4 method for class 'PqConnection,SQL'
dbQuoteString(conn, x, ...)

# S4 method for class 'PqConnection,character'
dbQuoteString(conn, x, ...)

# S4 method for class 'PqConnection,SQL'
dbUnquoteIdentifier(conn, x, ...)
```

## Arguments

- conn:

  A
  [PqConnection](https://rpostgres.r-dbi.org/reference/PqConnection-class.md)
  created by
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- x:

  A character vector to be quoted.

- ...:

  Other arguments needed for compatibility with generic (currently
  ignored).

## Examples

``` r
library(DBI)
con <- dbConnect(RPostgres::Postgres())

x <- c("a", "b c", "d'e", "\\f")
dbQuoteString(con, x)
#> <SQL> 'a'
#> <SQL> 'b c'
#> <SQL> 'd''e'
#> <SQL>  E'\\f'
dbQuoteIdentifier(con, x)
#> <SQL> "a"
#> <SQL> "b c"
#> <SQL> "d'e"
#> <SQL> "\f"
dbDisconnect(con)
```
