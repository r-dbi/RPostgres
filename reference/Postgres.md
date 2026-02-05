# Postgres driver

[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
establishes a connection to a database. Set `drv = Postgres()` to
connect to a PostgreSQL(-ish) database. Use `drv = Redshift()` instead
to connect to an AWS Redshift cluster.

Manually disconnecting a connection is not necessary with RPostgres, but
still recommended; if you delete the object containing the connection,
it will be automatically disconnected during the next GC with a warning.

## Usage

``` r
Postgres()

# S4 method for class 'PqDriver'
dbConnect(
  drv,
  dbname = NULL,
  host = NULL,
  port = NULL,
  password = NULL,
  user = NULL,
  service = NULL,
  ...,
  bigint = c("integer64", "integer", "numeric", "character"),
  check_interrupts = FALSE,
  timezone = "UTC",
  timezone_out = NULL
)

# S4 method for class 'PqConnection'
dbDisconnect(conn, ...)
```

## Arguments

- drv:

  [DBI::DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html).
  Use `Postgres()` to connect to a PostgreSQL(-ish) database or
  [`Redshift()`](https://rpostgres.r-dbi.org/reference/Redshift.md) to
  connect to an AWS Redshift cluster. Use an existing
  [DBI::DBIConnection](https://dbi.r-dbi.org/reference/DBIConnection-class.html)
  object to clone an existing connection.

- dbname:

  Database name. If `NULL`, defaults to the user name. Note that this
  argument can only contain the database name, it will not be parsed as
  a connection string (internally, `expand_dbname` is set to `false` in
  the call to
  [`PQconnectdbParams()`](https://www.postgresql.org/docs/current/libpq-connect.html)).

- host, port:

  Host and port. If `NULL`, will be retrieved from `PGHOST` and `PGPORT`
  env vars.

- user, password:

  User name and password. If `NULL`, will be retrieved from `PGUSER` and
  `PGPASSWORD` envvars, or from the appropriate line in `~/.pgpass`. See
  <https://www.postgresql.org/docs/current/libpq-pgpass.html> for more
  details.

- service:

  Name of service to connect as. If `NULL`, will be ignored. Otherwise,
  connection parameters will be loaded from the pg_service.conf file and
  used. See
  <https://www.postgresql.org/docs/current/libpq-pgservice.html> for
  details on this file and syntax.

- ...:

  Other name-value pairs that describe additional connection options as
  described at
  <https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-PARAMKEYWORDS>

- bigint:

  The R type that 64-bit integer types should be mapped to, default is
  [bit64::integer64](https://rdrr.io/pkg/bit64/man/bit64-package.html),
  which allows the full range of 64 bit integers.

- check_interrupts:

  Should user interrupts be checked during the query execution (before
  first row of data is available)? Setting to `TRUE` allows interruption
  of queries running too long.

- timezone:

  Sets the timezone for the connection. The default is `"UTC"`. If
  `NULL` then no timezone is set, which defaults to the server's time
  zone.

- timezone_out:

  The time zone returned to R, defaults to `timezone`. If you want to
  display datetime values in the local timezone, set to
  [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html) or `""`.
  This setting does not change the time values returned, only their
  display.

- conn:

  Connection to disconnect.

## Examples

``` r
library(DBI)
# Pass more arguments as necessary to dbConnect()
con <- dbConnect(RPostgres::Postgres())
dbDisconnect(con)
```
