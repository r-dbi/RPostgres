# RPostgres

RPostgres is an DBI-compliant interface to the postgres database. It's a ground-up rewrite using C++ and Rcpp. Compared to PostgresSQL, it:

* Has full support for parameterised queries via `dbSendQuery()`, and `dbBind()`.

* Automatically cleans up open connections and result sets, ensuring that you
  don't need to worry about leaking connections or memory.

* Is a little faster, saving ~5 ms per query. (For refernce, it takes around 5ms
  to retrive a 1000 x 25 result set from a local database, so this is 
  decent speed up for smaller queries.)

## Installation

RPostgres isn't available from CRAN yet, but you can get it from github with:

```R
# install.packages("devtools")
devtools::install_github("RcppCore/Rcpp")
devtools::install_github("rstats-db/DBI")
devtools::install_github("rstats-db/SQL")
devtools::install_github("rstats-dbi/RPostgres")
```


## Basic usage

```R
library(DBI)
# Connect to the default postgres database
con <- dbConnect(RPostgres::Postgres())

dbListTables(con)
dbWriteTable(con, "mtcars", mtcars)
dbListTables(con)

dbListFields(con, "mtcars")
dbReadTable(con, "mtcars")

# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
dbClearResult(res)

# Or a chunk at a time
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
while(!dbHasCompleted(res)){
  chunk <- dbFetch(res, n = 5)
  print(nrow(chunk))
}
# Clear the result
dbClearResult(res)

# Disconnect from the database
dbDisconnect(con)
```

## Design notes

The original DBI design imagined that each package could instantiate X drivers, with each driver having Y connections and each connection having Z results. This turns out to be too general: a driver has no real state, for PostgreSQL each connection can only have one result set. In the RPostgres package there's only one class on the C side: a connection, which optionally contains a result set. On the R side, the driver class is just a dummy class with no contents (used only for dispatch), and both the connection and result objects point to the same external pointer.
