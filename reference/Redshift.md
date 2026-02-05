# Redshift driver/connection

Use `drv = Redshift()` instead of `drv = Postgres()` to connect to an
AWS Redshift cluster. All methods in RPostgres and downstream packages
can be called on such connections. Some have different behavior for
Redshift connections, to ensure better interoperability.

## Usage

``` r
Redshift()

# S4 method for class 'RedshiftDriver'
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
  timezone = "UTC"
)
```

## Arguments

- drv:

  [DBI::DBIDriver](https://dbi.r-dbi.org/reference/DBIDriver-class.html).
  Use [`Postgres()`](https://rpostgres.r-dbi.org/reference/Postgres.md)
  to connect to a PostgreSQL(-ish) database or `Redshift()` to connect
  to an AWS Redshift cluster. Use an existing
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
