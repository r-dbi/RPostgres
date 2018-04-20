# RPostgres 1.1.0.9000 (2018-04-20)

- Same as previous version.


# RPostgres 1.1.0 (2018-04-04)

- Breaking change: `dbGetException()` is no longer reexported from DBI.
- Make "typname" information available after `dbFetch()` and `dbGetQuery()`. Values of unknown type are returned as character vector of class `"pq_xxx"`, where `"xxx"` is the "typname" returned from PostgreSQL. In particular, `JSON` and `JSONB` values now have class `"pq_json"` and `"pq_jsonb"`, respectively. The return value of `dbColumnInfo()` gains new columns `".oid"` (`integer`), `". known"` (`logical`) and `".typname"` (`character`)(#114, @etiennebr).
- Values of class `"integer64"` are now supported for `dbWriteTable()` and `dbBind()` (#178).
- Schema support, as specified by DBI: `dbListObjects()`, `dbUnquoteIdentifier()` and `Id()`.
- Names in the `x` argument to `dbQuoteIdentifier()` are preserved in the output (r-lib/DBI#173).
- All generics defined in DBI (e.g., `dbGetQuery()`) are now exported, even if the package doesn't provide a custom implementation (#168).
- Replace non-portable `timegm()` with private implementation.
- Correct reference to RPostgreSQL package (#165, @ClaytonJY).


# RPostgres 1.0-4 (2017-12-20)

- Only call `PQcancel()` if the query hasn't completed, fixes transactions on Amazon RedShift (#159, @mmuurr).
- Fix installation on MacOS.
- Check libpq version in configure script (need at least 9.0).
- Fix UBSAN warning: reference binding to null pointer (#156).
- Fix rchk warning: PROTECT internal temporary SEXP objects (#157).
- Fix severe memory leak when fetching results (#154).

# RPostgres 1.0-3 (2017-12-01)

Initial release, compliant to the DBI specification.

- Test almost all test cases of the DBI specification.
- Fully support parametrized queries.
- Spec-compliant transactions.
- 64-bit integers are now supported through the `bit64` package. This also means that numeric literals (as in `SELECT 1`) are returned as 64-bit integers. The `bigint` argument to `dbConnect()` allows overriding the data type on a per-connection basis.
- Correct handling of DATETIME and TIME columns.
- New default `row.names = FALSE`.
