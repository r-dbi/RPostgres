# Wait for and return any notifications that return within timeout

Once you subscribe to notifications with LISTEN, use this to wait for
responses on each channel.

## Usage

``` r
postgresWaitForNotify(conn, timeout = 1)
```

## Arguments

- conn:

  a
  [PqConnection](https://rpostgres.r-dbi.org/dev/reference/PqConnection-class.md)
  object, produced by
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)

- timeout:

  How long to wait, in seconds. Default 1

## Value

If a notification was available, a list of:

- channel:

  Name of channel

- pid:

  PID of notifying server process

- payload:

  Content of notification

If no notifications are available, return NULL

## Examples

``` r
library(DBI)
library(callr)

# listen for messages on the grapevine
db_listen <- dbConnect(RPostgres::Postgres())
dbExecute(db_listen, "LISTEN grapevine")
#> [1] 0

# Start another process, which sends a message after a delay
rp <- r_bg(function() {
  library(DBI)
  Sys.sleep(0.3)
  db_notify <- dbConnect(RPostgres::Postgres())
  dbExecute(db_notify, "NOTIFY grapevine, 'psst'")
  dbDisconnect(db_notify)
})

# Sleep until we get the message
n <- NULL
while (is.null(n)) {
  n <- RPostgres::postgresWaitForNotify(db_listen, 60)
}
stopifnot(n$payload == 'psst')

# Tidy up
rp$wait()
dbDisconnect(db_listen)
```
