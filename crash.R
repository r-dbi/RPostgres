env <- new.env(parent = emptyenv())
reg.finalizer(env, function(env) {
  lapply(unique(as.list(env)), function(x) {
    show(x)
    ##if(inherits(x, "DBIConnection")) try(DBI::dbDisconnect(x))
  })
})
env$conn1 <- DBI::dbConnect(RPostgres::Postgres()) ## conn1 params here
env$conn2 <- DBI::dbConnect(RPostgres::Postgres()) ## conn2 params here

rm(env)
gc()
