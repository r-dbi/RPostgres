# RPostgres 1.0-4

- Fix installation on MacOS
- Check libpq version in configure script (need at least 9.0)
- Fix UBSAN warning: reference binding to null pointer (#156)
- Fix rchk warning: PROTECT internal temporary SEXP objects (#157)

# RPostgres 1.0-3 (2017-12-01)

Initial release, compliant to the DBI specification.

- Test almost all test cases of the DBI specification.
- Fully support parametrized queries.
- Spec-compliant transactions.
- 64-bit integers are now supported through the `bit64` package. This also means that numeric literals (as in `SELECT 1`) are returned as 64-bit integers. The `bigint` argument to `dbConnect()` allows overriding the data type on a per-connection basis.
- Correct handling of DATETIME and TIME columns.
- New default `row.names = FALSE`.
