if (!require(covr)) install.packages("covr")
if (!require(DBItest)) install.packages("DBItest")
devtools::install(upgrade = "never")
devtools::check()
