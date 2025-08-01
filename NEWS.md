<!-- NEWS.md is maintained by https://fledge.cynkra.com, contributors should not edit this file -->

# RPostgres 1.4.7.9903 (2025-08-01)

## Continuous integration

- Format with air, check detritus, better handling of `extra-packages` (#510).


# RPostgres 1.4.7.9902 (2025-05-04)

## Continuous integration

- Enhance permissions for workflow (#506).


# RPostgres 1.4.7.9901 (2025-04-30)

## Continuous integration

- Permissions, better tests for missing suggests, lints (#504).

- Only fail covr builds if token is given (#501).

- Always use `_R_CHECK_FORCE_SUGGESTS_=false` (#500).

- Correct installation of xml2 (#497).

- Explain (#495).

- Add xml2 for covr, print testthat results (#494).

- Sync (#493).


# RPostgres 1.4.7.9900 (2025-02-24)

## Windows

- Update libpq fallback library (#489).

- Use libpq from Rtools if available (#486).

## Features

- Importing large objects from client side (@toppyy, #376, #472).

## Chore

- IDE.

- Auto-update from GitHub Actions.

  Run: https://github.com/r-dbi/RPostgres/actions/runs/10425486593

  Run: https://github.com/r-dbi/RPostgres/actions/runs/10224248168

  Run: https://github.com/r-dbi/RPostgres/actions/runs/10200112323

  Run: https://github.com/r-dbi/RPostgres/actions/runs/9728443553

  Run: https://github.com/r-dbi/RPostgres/actions/runs/9692464325

## Continuous integration

- Test on older Windows versions.

- Avoid failure in fledge workflow if no changes (#479).

- Remove Aviator.

- Fetch tags for fledge workflow to avoid unnecessary NEWS entries (#478).

- Use stable pak (#477).

- Latest changes (#475).

- Import from actions-sync, check carefully (#474).

- Use pkgdown branch (#473).

  - ci: Use pkgdown branch

  - ci: Updates from duckdb

  - ci: Trigger run

- Install via R CMD INSTALL ., not pak (#471).

  - ci: Install via R CMD INSTALL ., not pak

  - ci: Bump version of upload-artifact action

- Install local package for pkgdown builds.

- Improve support for protected branches with fledge.

- Improve support for protected branches, without fledge.

- Sync with latest developments.

- Use v2 instead of master.

- Inline action.

- Use dev roxygen2 and decor.

- Fix on Windows, tweak lock workflow.

- Avoid checking bashisms on Windows.

- Allow NOTEs on R-devel.

- Better commit message.

- Bump versions, better default, consume custom matrix.

- Recent updates.

## Uncategorized

- Merge branch 'cran-1.4.7'.


# RPostgres 1.4.7 (2024-05-26)

## Features

- Breaking change: Avoid appending a numeric suffix to duplicate column names (#463).

## Bug fixes

- `dbWriteTable()` correctly handles name clashes between temporary and permanent tables (#402, #431).
- Fix `dbQuoteIdentifier()` for `Id()` objects to no longer rely on names (#460).

## Chore

- Bump preferred libpq version on MacOS to 15 (#441, #465).
- Refactor `dbListTables()` et al. (@dpprdan, #413).
- Refactor `list_fields()` (#462).
- Use `Id` in `exists_table()` (#461).

## Documentation

- Use dbitemplate (@maelle, #456).

## Testing

- Test for columns in `dbQuoteIdentifier()` (@dpprdan, #263, #372).
- Fix tests if DBItest is not installed (#448).


# RPostgres 1.4.6 (2023-10-22)

## Breaking changes

- Breaking change: `dbListObjects()` only allows `Id()` objects as `prefix` argument (@dpprdan, #390).

## Bug fixes

- Use `NULL` in favor of `NULL::text` when quoting strings and literals, to support JSON and other text-ish types. Fixes a regression introduced in #370 (#393, #425).

## Features

- `dbQuoteLiteral()` correctly quotes 64-bit integers from the bit64 package (of class `"integer64"`) (@karawoo, #435, #436).

- Breaking change: `dbListObjects()` only allows `Id()` objects as `prefix` argument (@dpprdan, #390).

## Libraries

- Windows: update to libpq-15.3 (#442).

- Upgrade boost to 1.81.0-1 to fix sprintf warnings (#417).

## Documentation

- Suppress warning in gcc-12 (#443).

- Tweak driver docs (@dpprdan, #433).

- Relicense as MIT.

## Testing

- Close result set.

## Internal

- Replace Rcpp by cpp11 (@Antonov548, #419).


# RPostgres 1.4.5 (2023-01-19)

## Features

- Upgrade boost to 1.81.0-1 to fix sprintf warnings (#417).

- One-click setup for https://gitpod.io (@Antonov548, #407).

- Use testthat edition 3 (#408).


# RPostgres 1.4.4 (2022-05-01)

## Bug fixes

- Allow connection if the `pg_type` table is missing (#394, #395, @pedrobtz).
- Fix `dbExecute(immediate = TRUE)` after `dbAppendTable()` (#382, #384).

## Internal

- Expand tests for `dbConnect(check_interrupts = TRUE)` (#385, @zozlak).
- Ignore extended timestamp tests on i386 (#387).


# RPostgres 1.4.3 (2021-12-20)

## Features

- New `postgresIsTransacting()` (#351, @jakob-r).
- Temporary tables are now discovered correctly for `Redshift()` connections, all DBItest tests pass (#358, @galachad).

## Internal

- Make method definition more similar to S3. All `setMethod()` calls refer to top-level functions (#380).


# RPostgres 1.4.2 (2021-12-05)

## Features

- `dbWriteTable()` uses savepoints for its transactions, even if an external transaction is open. This does not affect Redshift, because savepoints are not supproted there (#342).
- With `dbConnect(check_interrupts = TRUE)`, interrupting a query now gives a dedicated error message. Very short-running queries no longer take one second to complete (#344).

## Bug fixes

- `dbQuoteLiteral()` correctly quotes length-0 values (#355) and generates typed `NULL` expressions for `NA` values (#357).
- The `SET DATESTYLE` query sent after connecting uses quotes for compatibility with CockroachDB (#360).

## Internal

- `dbConnect()` executes initial queries with `immediate = TRUE` (#346).
- Check Postgres starting from version 10 on GitHub Actions (#368).
- Fix build on Ubuntu 16.04 (#352).
- Mention `libssl-dev` in `configure` script (#350).


# RPostgres 1.4.1 (2021-09-26)

## Bug fixes

- Avoid crash by dereferencing 0-size vector (#343). 


# RPostgres 1.4.0 (2021-09-25)

## Features

- `Redshift()` connections now adhere to almost all of the DBI specification when connecting to a Redshift cluster. BLOBs are not supported on Redshift, and there are limitations with enumerating temporary and persistent tables (#215, #326).
- `dbBegin()`, `dbCommit()` and `dbRollback()` gain `name` argument to support savepoints. An unnamed transaction must be started beforehand (#13).
- `dbWriteTable()` uses a transaction (#307).
- `dbSendQuery()` gains `immediate` argument. Multiple queries (separated by semicolons) can be passed in this mode, query parameters are not supported (#272).
- `dbConnect(check_interrupts = TRUE)` now aborts a running query faster and more reliably when the user signals an interrupt, e.g. by pressing Ctrl+C (#336).
- `dbAppendTable()` gains `copy` argument. If set to `TRUE`, data is imported via `COPY name FROM STDIN` (#241, @hugheylab).
- Postgres `NOTICE` messages are now forwarded as proper R messages and can be captured and suppressed (#208).

## Bug fixes

- `dbQuoteLiteral()` converts timestamp values to input time zone, used when writing tables to Redshift (#325).

## Internal

- Skip timestamp tests on i386 (#318).
- `dbSendQuery()` and `dbQuoteLiteral()` use single dispatch (#320).
- `dbWriteTable()` and `dbAppendTable()` default to `copy = NULL`, this translates to `TRUE` for `Postgres()` and `FALSE` for `Redshift()` connections (#329). 

## Documentation

- Order help topics on pkgdown site.
- Use `@examplesIf` in method documentation.
- Document when `field.types` is used in `dbWriteTable()` (#206).
- Document setting the tablespace before writing a table (#246).
- Tweak error message for named `params` argument to `dbBind()` (#266).


# RPostgres 1.3.3 (2021-07-05)

- Fix `dbConnect(check_interrupts = TRUE)` on Windows (#244, @zozlak).
- Windows: update to libpq 13.2.0 and add UCRT support (#309, @jeroen).


# RPostgres 1.3.2 (2021-04-12)

- Remove BH dependency by inlining the header files (#300).
- Use Autobrew if libpq is older than version 12 (#294, @jeroen).
- `dbConnect()` now issues `SET datestyle to iso, mdy` to avoid translation errors for datetime values with databases configured differently (#287, @baderstine).


# RPostgres 1.3.1 (2021-01-19)

## Bug fixes

- `Inf`, `-Inf` and `NaN` values are returned correctly on Windows (#267).
- Fix behavior with invalid time zone (#284, @ateucher).

## Internal

- `dbConnect()` defaults to `timezone_out = NULL`, this means to use `timezone`.
- `FORCE_AUTOBREW` environment variable enforces use of `autobrew` in `configure` (#283, @jeroen).
- Fix `configure` on macOS, small tweaks (#282, #283, @jeroen).
- Fix `configure` script, remove `$()` not reliably detected by `checkbashisms`.
- `configure` uses a shell script and no longer forwards to `src/configure.bash` (#265).


# RPostgres 1.3.0 (2021-01-05)

- `dbConnect()` gains `timezone_out` argument, the default `NULL` means to use `timezone` (#222).
- `dbQuoteLiteral()` now quotes difftime values as `interval` (#270).
- New `postgresWaitForNotify()` adds `LISTEN/NOTIFY` support (#237, @lentinj).

## Bug fixes

- `Inf`, `-Inf` and `NaN` values are returned correctly on Windows (#267).
- `DATETIME` values (=without time zone) and `DATETIMETZ` values (=with time zone) are returned correctly (#190, #205, #229), also if they start before 1970 (#221).

## Internal

- `configure` uses a shell script and no longer forwards to `src/configure.bash` (#265).
- Switch to GitHub Actions (#268, thanks @ankane).
- Now imports the lubridate package.


# RPostgres 1.2.1 (2020-09-28)

- Gains new `Redshift` driver for connecting to Redshift databases.
  Redshift databases behave almost identically to Postgres so this
  driver allows downstream packages to distinguish between the two (#258).
- Datetime values are now passed to the database using an unambiguous time zone format (#255, @imlijunda).
- Document `Postgres()` together with `dbConnect()` (#242).
- Windows: update libpq to 12.2.0.

# RPostgres 1.2.0 (2019-12-18)

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


# RPostgres 1.1.3 (2019-12-07)

- Replace `std::mem_fn()` by `boost::mem_fn()` which works for older compilers.


# RPostgres 1.1.2 (2019-12-03)

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
- Names in the `x` argument to `dbQuoteIdentifier()` are preserved in the output (r-dbi/DBI#173).
- All generics defined in DBI (e.g., `dbGetQuery()`) are now exported, even if the package doesn't provide a custom implementation (#168).
- Replace non-portable `timegm()` with private implementation.
- Correct reference to RPostgreSQL package (#165, @ClaytonJY).


# RPostgres 1.0-4 (2017-12-20)

- Only call `PQcancel()` if the query hasn't completed, fixes transactions on Amazon Redshift (#159, @mmuurr).
- Fix installation on macOS.
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
