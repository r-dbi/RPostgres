<<<<<<< HEAD
## RPostgres 0.1-12 (2017-12-02)

- Eliminated race condition that could lead to `"Query cancelled on user's request"` errors (#145).
- Prepare for CRAN release.
- CI for OS X and Windows (#69).
- `dbQuoteString()` no longer adds `::varchar` suffix (#146).


## RPostgres 0.1-11 (2017-12-01)
||||||| merged common ancestors
## RPostgres 0.1-11 (2017-12-01)
=======
# RPostgres 1.0 (2017-12-01)
>>>>>>> NEWS

Initial release, compliant to the DBI specification.

- Test almost all test cases of the DBI specification.
- Fully support parametrized queries.
- Spec-compliant transactions.
- 64-bit integers are now supported through the `bit64` package. This also means that numeric literals (as in `SELECT 1`) are returned as 64-bit integers. The `bigint` argument to `dbConnect()` allows overriding the data type on a per-connection basis.
- Correct handling of DATETIME and TIME columns.
- New default `row.names = FALSE`.
