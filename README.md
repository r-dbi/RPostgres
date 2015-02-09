# rpq

Experimental [libpq](http://www.postgresql.org/docs/9.4/static/libpq.html) bindings for R. [DBI](http://github.com/rstats-db/DBI) compatible; built with [Rcpp](http://rcpp.org). The goal is to explore what a modern binding might look like, taking advantage of all the best features of C++ and Rcpp, not to produce a package for CRAN.

The original DBI design imagined that each package could instantiate X drivers, with each driver having Y connections and each connection having Z results. This turns out to be too general: a driver has no real state, for PostgreSQL each connection can only have one result set. In the rpq package there's only one class on the C side: a connection, which optionally contains a result set. On the R side, the driver class is just a dummy class with no contents (used only for dispatch), and both the connection and result objects point to the same external pointer.

Unlike other database drivers, postgresql queries always run to completion. If you want to retrieve a chunk of results at a time, delaying computation, you'll need to use a [CURSOR](http://www.postgresql.org/docs/9.2/static/plpgsql-cursors.html).

Currently this adapter makes two copies of the data retrieve from a query: one by libpq, and one in the returned dataframe. It would be possible to eliminate one copy by implementing the postgre binary protocol directly, but this is a lot of work.
