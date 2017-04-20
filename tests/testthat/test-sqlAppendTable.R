con <- dbConnect(RPostgres::Postgres())

tblname <- "fuutab"

dbExecute(con, sprintf("CREATE TEMPORARY TABLE %s
    (
    id SERIAL8 PRIMARY KEY,
    chr VARCHAR(255),
    num1 INT,
    num2 FLOAT,
    lgl BOOL
    );", tblname))

dat <- data.frame(chr = c('Abc', 'Def', NA),
                  num1 = c(59000000 + 0:1, NA),
                  num2 = pi * c(1, 2, NA),
                  lgl = c(TRUE, FALSE, NA))

qry <- sqlAppendTable(con, tblname, dat)

expect_equal(dbExecute(con, qry), nrow(dat))

ret <- dbGetQuery(con, paste("SELECT * FROM", tblname))

expect_true(nrow(ret) > 0)

dbDisconnect(con)
