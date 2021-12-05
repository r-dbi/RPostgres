# RPostgres

<!-- badges: start -->
[![rcc](https://github.com/r-dbi/RPostgres/workflows/rcc/badge.svg)](https://github.com/r-dbi/RPostgres/actions)
[![Codecov test coverage](https://codecov.io/gh/r-dbi/RPostgres/branch/master/graph/badge.svg)](https://app.codecov.io/gh/r-dbi/RPostgres?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/RPostgres)](https://CRAN.R-project.org/package=RPostgres)
<!-- badges: end -->

RPostgres is an DBI-compliant interface to the postgres database. It's a ground-up rewrite using C++ and Rcpp. Compared to RPostgreSQL, it:

* Has full support for parameterised queries via `dbSendQuery()`, and `dbBind()`.

* Automatically cleans up open connections and result sets, ensuring that you
  don't need to worry about leaking connections or memory.

* Is a little faster, saving ~5 ms per query. (For reference, it takes around 5ms
  to retrieve a 1000 x 25 result set from a local database, so this is 
  decent speed up for smaller queries.)

* A simplified build process that relies on system libpq.

## Installation
```R
# Install the latest RPostgres release from CRAN:
install.packages("RPostgres")

# Or the the development version from GitHub:
# install.packages("remotes")
remotes::install_github("r-dbi/RPostgres")
```

Discussions associated with DBI and related database packages take place on [R-SIG-DB](https://stat.ethz.ch/mailman/listinfo/r-sig-db). 
The website [Databases using R](https://db.rstudio.com/) describes the tools and best practices in this ecosystem.

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
## Connecting to a specific Postgres instance

```R
library(DBI)
# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(),dbname = 'DATABASE_NAME', 
                 host = 'HOST', # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
                 port = 5432, # or any other port specified by your DBA
                 user = 'USERNAME',
                 password = 'PASSWORD')

```

## Design notes

The original DBI design imagined that each package could instantiate X drivers, with each driver having Y connections and each connection having Z results. This turns out to be too general: a driver has no real state, for PostgreSQL each connection can only have one result set. In the RPostgres package there's only one class on the C side: a connection, which optionally contains a result set. On the R side, the driver class is just a dummy class with no contents (used only for dispatch), and both the connection and result objects point to the same external pointer.

---

Please note that the 'RPostgres' project is released with a
[Contributor Code of Conduct](https://rpostgres.r-dbi.org/code_of_conduct).
By contributing to this project, you agree to abide by its terms.
