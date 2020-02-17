# RPostgres 1.2.0.9000

- Windows: update libpq to 12.2.0.

# RPostgres 1.2.0

## Communication with the database

- Breaking: Translate floating-point values to `DOUBLE PRECISION` by default (#194).
- Avoid aggressive rounding when passing numeric values to the database (#184).
- Avoid adding extra spaces for numerics (#216).
- Column names and error messages are UTF-8 encoded (#172).
- `dbWriteTable(copy = FALSE)`, `sqlData()` and `dbAppendTable()` now work for character columns (#209), which are always converted to UTF-8.

## New features

- Add `timezone` argument to `dbConnect()` (#187, @trafficonese).
- Implement `dbGetInfo()` for the driver and the connection object.
- `dbConnect()` gains `check_interrupts` argument that allows interrupting execution safely while waiting for query results to be ready (#193, @zozlak).
- `dbUnquoteIdentifier()` also handles unquoted identifiers of the form `table` or `schema.table`, for compatibility with dbplyr. In addition, a `catalog` component is supported for quoting and unquoting with `Id()`.
- `dbQuoteLiteral()` available for `"character"` (#209).
- Windows: update libpq to 11.1.0.
- Fulfill CII badge requirements (#227, @TSchiefer).

## Bug fixes

- Hide unused symbols in shared library (#230, @troels).
- Fix partial argument matching in `dbAppendTable()` (r-dbi/DBI#249).
- Fix binding for whole numbers and `POSIXt` timestamps (#191).

## Internal

- `sqlData(copy = FALSE)` now uses `dbQuoteLiteral()` (#209).
- Add tests for `dbUnquoteIdentifier()` (#220, @baileych).
- Improved tests for numerical precision (#203, @harvey131).
- Fix test: change from `REAL` to `DOUBLE PRECISION` (#204, @harvey131).
- Implement `dbAppendTable()` for own connection class, don't hijack base class implementation (r-dbi/RMariaDB#119).
- Avoid including the call in errors.
- Align `DbResult` and other classes with RSQLite and RMariaDB.


# RPostgres 1.1.3

- Replace `std::mem_fn()` by `boost::mem_fn()` which works for older compilers.


# RPostgres 1.1.2

- Replace `std::mem_fun_ref()` by `std::mem_fn()`.


# RPostgres 1.1.1 (2018-05-05)

- Add support for `bigint` argument to `dbConnect()`, supported values are `"integer64"`, `"integer"`, `"numeric"` and `"character"`. Large integers are returned as values of that type (r-dbi/DBItest#133).
- Data frames resulting from a query always have unique non-empty column names (r-dbi/DBItest#137).
- New arguments `temporary` and `fail_if_missing` (default: `TRUE`) to `dbRemoveTable()` (r-dbi/DBI#141, r-dbi/DBI#197).
- Using `dbCreateTable()` and `dbAppendTable()` internally (r-dbi/DBI#74).
- The `field.types` argument to `dbWriteTable()` now must be named.
- Using `current_schemas(true)` also in `dbListObjects()` and `dbListTables()`, for consistency with `dbListFields()`. Objects from the `pg_catalog` schema are still excluded.
- `dbListFields()` doesn't list fields from tables found in the `pg_catalog` schema.
- The `dbListFields()` method now works correctly if the `name` argument is a quoted identifier or of class `Id`, and throws an error if the table is not found (r-dbi/DBI#75).
- Implement `format()` method for `SqliteConnection` (r-dbi/DBI#163).
- Reexporting `Id()`, `DBI::dbIsReadOnly()` and `DBI::dbCanConnect()`.
- Now imports DBI 1.0.0.


# RPostgres 1.1.0 (2018-04-04)

- Breaking change: `dbGetException()` is no longer reexported from DBI.
- Make "typname" information available after `dbFetch()` and `dbGetQuery()`. Values of unknown type are returned as character vector of class `"pq_xxx"`, where `"xxx"` is the "typname" returned from PostgreSQL. In particular, `JSON` and `JSONB` values now have class `"pq_json"` and `"pq_jsonb"`, respectively. The return value of `dbColumnInfo()` gains new columns `".oid"` (`integer`), `". known"` (`logical`) and `".typname"` (`character`) (#114, @etiennebr).
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
