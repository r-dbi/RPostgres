# Package index

## Connecting and disconnecting

Connecting to and disconnecting from a database.

- [`Postgres()`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  [`dbConnect(`*`<PqDriver>`*`)`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  [`dbDisconnect(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  : Postgres driver
- [`Redshift()`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md)
  [`dbConnect(`*`<RedshiftDriver>`*`)`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md)
  : Redshift driver/connection

## Tables

Reading and writing entire tables.

- [`dbAppendTable(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbExistsTable(`*`<PqConnection>`*`,`*`<Id>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbExistsTable(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbListFields(`*`<PqConnection>`*`,`*`<Id>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbListFields(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbListObjects(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbListTables(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbReadTable(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbRemoveTable(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`dbWriteTable(`*`<PqConnection>`*`,`*`<character>`*`,`*`<data.frame>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  [`sqlData(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-tables.md)
  : Convenience functions for reading/writing DBMS tables
- [`dbQuoteIdentifier(`*`<PqConnection>`*`,`*`<Id>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbQuoteIdentifier(`*`<PqConnection>`*`,`*`<SQL>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbQuoteIdentifier(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbQuoteLiteral(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbQuoteString(`*`<PqConnection>`*`,`*`<SQL>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbQuoteString(`*`<PqConnection>`*`,`*`<character>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  [`dbUnquoteIdentifier(`*`<PqConnection>`*`,`*`<SQL>`*`)`](https://rpostgres.r-dbi.org/dev/reference/quote.md)
  : Quote postgres strings, identifiers, and literals

## Queries and statements

Sending queries and executing statements.

- [`dbBind(`*`<PqResult>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-query.md)
  [`dbClearResult(`*`<PqResult>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-query.md)
  [`dbFetch(`*`<PqResult>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-query.md)
  [`dbHasCompleted(`*`<PqResult>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-query.md)
  [`dbSendQuery(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-query.md)
  : Execute a SQL statement on a database connection

## Transactions

Ensuring multiple statements are executed together, or not at all.

- [`dbBegin(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-transactions.md)
  [`dbCommit(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-transactions.md)
  [`dbRollback(`*`<PqConnection>`*`)`](https://rpostgres.r-dbi.org/dev/reference/postgres-transactions.md)
  : Transaction management.
- [`postgresIsTransacting()`](https://rpostgres.r-dbi.org/dev/reference/postgresIsTransacting.md)
  : Return whether a transaction is ongoing

## Misellaneous

Functions specific to Postgres

- [`RPostgres`](https://rpostgres.r-dbi.org/dev/reference/RPostgres-package.md)
  [`RPostgres-package`](https://rpostgres.r-dbi.org/dev/reference/RPostgres-package.md)
  : RPostgres: C++ Interface to PostgreSQL
- [`postgresHasDefault()`](https://rpostgres.r-dbi.org/dev/reference/postgresHasDefault.md)
  [`postgresDefault()`](https://rpostgres.r-dbi.org/dev/reference/postgresHasDefault.md)
  : Check if default database is available.
- [`postgresWaitForNotify()`](https://rpostgres.r-dbi.org/dev/reference/postgresWaitForNotify.md)
  : Wait for and return any notifications that return within timeout
- [`postgresImportLargeObject()`](https://rpostgres.r-dbi.org/dev/reference/postgresImportLargeObject.md)
  : Imports a large object from file
- [`postgresExportLargeObject()`](https://rpostgres.r-dbi.org/dev/reference/postgresExportLargeObject.md)
  : Exports a large object to file
