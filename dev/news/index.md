# Changelog

## RPostgres 1.4.8.9003 (2025-11-11)

### Continuous integration

- Use workflows for fledge
  ([\#531](https://github.com/r-dbi/RPostgres/issues/531)).

## RPostgres 1.4.8.9002 (2025-11-08)

### Continuous integration

- Sync ([\#529](https://github.com/r-dbi/RPostgres/issues/529)).

## RPostgres 1.4.8.9001 (2025-09-23)

### Features

- New
  [`postgresExportLargeObject()`](https://rpostgres.r-dbi.org/dev/reference/postgresExportLargeObject.md)
  function for exporting large objects to files
  ([\#519](https://github.com/r-dbi/RPostgres/issues/519),
  [\#520](https://github.com/r-dbi/RPostgres/issues/520)).

### Chore

- Auto-update from GitHub Actions
  ([\#524](https://github.com/r-dbi/RPostgres/issues/524)).

## RPostgres 1.4.8.9000 (2025-09-14)

### Chore

- Auto-update from GitHub Actions
  ([\#515](https://github.com/r-dbi/RPostgres/issues/515)).

### Continuous integration

- Default to PostgreSQL 17.

- Use reviewdog for external PRs
  ([\#517](https://github.com/r-dbi/RPostgres/issues/517)).

- Cleanup and fix macOS
  ([\#512](https://github.com/r-dbi/RPostgres/issues/512)).

- Format with air, check detritus, better handling of `extra-packages`
  ([\#510](https://github.com/r-dbi/RPostgres/issues/510)).

- Enhance permissions for workflow
  ([\#506](https://github.com/r-dbi/RPostgres/issues/506)).

- Permissions, better tests for missing suggests, lints
  ([\#504](https://github.com/r-dbi/RPostgres/issues/504)).

- Only fail covr builds if token is given
  ([\#501](https://github.com/r-dbi/RPostgres/issues/501)).

- Always use `_R_CHECK_FORCE_SUGGESTS_=false`
  ([\#500](https://github.com/r-dbi/RPostgres/issues/500)).

- Correct installation of xml2
  ([\#497](https://github.com/r-dbi/RPostgres/issues/497)).

- Explain ([\#495](https://github.com/r-dbi/RPostgres/issues/495)).

- Add xml2 for covr, print testthat results
  ([\#494](https://github.com/r-dbi/RPostgres/issues/494)).

- Sync ([\#493](https://github.com/r-dbi/RPostgres/issues/493)).

### Documentation

- Add comprehensive GitHub Copilot instructions
  ([\#522](https://github.com/r-dbi/RPostgres/issues/522)).

## RPostgres 1.4.8 (2025-02-25)

### Windows

- Use libpq from Rtools if available
  ([\#486](https://github.com/r-dbi/RPostgres/issues/486)), update libpq
  fallback library
  ([\#489](https://github.com/r-dbi/RPostgres/issues/489)).

### Features

- New
  [`postgresImportLargeObject()`](https://rpostgres.r-dbi.org/dev/reference/postgresImportLargeObject.md)
  for importing large objects from client side
  ([@toppyy](https://github.com/toppyy),
  [\#376](https://github.com/r-dbi/RPostgres/issues/376),
  [\#472](https://github.com/r-dbi/RPostgres/issues/472)).

## RPostgres 1.4.7 (2024-05-26)

### Features

- Breaking change: Avoid appending a numeric suffix to duplicate column
  names ([\#463](https://github.com/r-dbi/RPostgres/issues/463)).

### Bug fixes

- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  correctly handles name clashes between temporary and permanent tables
  ([\#402](https://github.com/r-dbi/RPostgres/issues/402),
  [\#431](https://github.com/r-dbi/RPostgres/issues/431)).
- Fix
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  for [`Id()`](https://dbi.r-dbi.org/reference/Id.html) objects to no
  longer rely on names
  ([\#460](https://github.com/r-dbi/RPostgres/issues/460)).

### Chore

- Bump preferred libpq version on MacOS to 15
  ([\#441](https://github.com/r-dbi/RPostgres/issues/441),
  [\#465](https://github.com/r-dbi/RPostgres/issues/465)).
- Refactor
  [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html)
  et al. ([@dpprdan](https://github.com/dpprdan),
  [\#413](https://github.com/r-dbi/RPostgres/issues/413)).
- Refactor `list_fields()`
  ([\#462](https://github.com/r-dbi/RPostgres/issues/462)).
- Use `Id` in `exists_table()`
  ([\#461](https://github.com/r-dbi/RPostgres/issues/461)).

### Documentation

- Use dbitemplate ([@maelle](https://github.com/maelle),
  [\#456](https://github.com/r-dbi/RPostgres/issues/456)).

### Testing

- Test for columns in
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  ([@dpprdan](https://github.com/dpprdan),
  [\#263](https://github.com/r-dbi/RPostgres/issues/263),
  [\#372](https://github.com/r-dbi/RPostgres/issues/372)).
- Fix tests if DBItest is not installed
  ([\#448](https://github.com/r-dbi/RPostgres/issues/448)).

## RPostgres 1.4.6 (2023-10-22)

### Breaking changes

- Breaking change:
  [`dbListObjects()`](https://dbi.r-dbi.org/reference/dbListObjects.html)
  only allows [`Id()`](https://dbi.r-dbi.org/reference/Id.html) objects
  as `prefix` argument ([@dpprdan](https://github.com/dpprdan),
  [\#390](https://github.com/r-dbi/RPostgres/issues/390)).

### Bug fixes

- Use `NULL` in favor of `NULL::text` when quoting strings and literals,
  to support JSON and other text-ish types. Fixes a regression
  introduced in [\#370](https://github.com/r-dbi/RPostgres/issues/370)
  ([\#393](https://github.com/r-dbi/RPostgres/issues/393),
  [\#425](https://github.com/r-dbi/RPostgres/issues/425)).

### Features

- [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  correctly quotes 64-bit integers from the bit64 package (of class
  `"integer64"`) ([@karawoo](https://github.com/karawoo),
  [\#435](https://github.com/r-dbi/RPostgres/issues/435),
  [\#436](https://github.com/r-dbi/RPostgres/issues/436)).

- Breaking change:
  [`dbListObjects()`](https://dbi.r-dbi.org/reference/dbListObjects.html)
  only allows [`Id()`](https://dbi.r-dbi.org/reference/Id.html) objects
  as `prefix` argument ([@dpprdan](https://github.com/dpprdan),
  [\#390](https://github.com/r-dbi/RPostgres/issues/390)).

### Libraries

- Windows: update to libpq-15.3
  ([\#442](https://github.com/r-dbi/RPostgres/issues/442)).

- Upgrade boost to 1.81.0-1 to fix sprintf warnings
  ([\#417](https://github.com/r-dbi/RPostgres/issues/417)).

### Documentation

- Suppress warning in gcc-12
  ([\#443](https://github.com/r-dbi/RPostgres/issues/443)).

- Tweak driver docs ([@dpprdan](https://github.com/dpprdan),
  [\#433](https://github.com/r-dbi/RPostgres/issues/433)).

- Relicense as MIT.

### Testing

- Close result set.

### Internal

- Replace Rcpp by cpp11 ([@Antonov548](https://github.com/Antonov548),
  [\#419](https://github.com/r-dbi/RPostgres/issues/419)).

## RPostgres 1.4.5 (2023-01-19)

### Features

- Upgrade boost to 1.81.0-1 to fix sprintf warnings
  ([\#417](https://github.com/r-dbi/RPostgres/issues/417)).

- One-click setup for <https://gitpod.io>
  ([@Antonov548](https://github.com/Antonov548),
  [\#407](https://github.com/r-dbi/RPostgres/issues/407)).

- Use testthat edition 3
  ([\#408](https://github.com/r-dbi/RPostgres/issues/408)).

## RPostgres 1.4.4 (2022-05-01)

### Bug fixes

- Allow connection if the `pg_type` table is missing
  ([\#394](https://github.com/r-dbi/RPostgres/issues/394),
  [\#395](https://github.com/r-dbi/RPostgres/issues/395),
  [@pedrobtz](https://github.com/pedrobtz)).
- Fix `dbExecute(immediate = TRUE)` after
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  ([\#382](https://github.com/r-dbi/RPostgres/issues/382),
  [\#384](https://github.com/r-dbi/RPostgres/issues/384)).

### Internal

- Expand tests for `dbConnect(check_interrupts = TRUE)`
  ([\#385](https://github.com/r-dbi/RPostgres/issues/385),
  [@zozlak](https://github.com/zozlak)).
- Ignore extended timestamp tests on i386
  ([\#387](https://github.com/r-dbi/RPostgres/issues/387)).

## RPostgres 1.4.3 (2021-12-20)

### Features

- New
  [`postgresIsTransacting()`](https://rpostgres.r-dbi.org/dev/reference/postgresIsTransacting.md)
  ([\#351](https://github.com/r-dbi/RPostgres/issues/351),
  [@jakob-r](https://github.com/jakob-r)).
- Temporary tables are now discovered correctly for
  [`Redshift()`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md)
  connections, all DBItest tests pass
  ([\#358](https://github.com/r-dbi/RPostgres/issues/358),
  [@galachad](https://github.com/galachad)).

### Internal

- Make method definition more similar to S3. All
  [`setMethod()`](https://rdrr.io/r/methods/setMethod.html) calls refer
  to top-level functions
  ([\#380](https://github.com/r-dbi/RPostgres/issues/380)).

## RPostgres 1.4.2 (2021-12-05)

### Features

- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  uses savepoints for its transactions, even if an external transaction
  is open. This does not affect Redshift, because savepoints are not
  supproted there
  ([\#342](https://github.com/r-dbi/RPostgres/issues/342)).
- With `dbConnect(check_interrupts = TRUE)`, interrupting a query now
  gives a dedicated error message. Very short-running queries no longer
  take one second to complete
  ([\#344](https://github.com/r-dbi/RPostgres/issues/344)).

### Bug fixes

- [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  correctly quotes length-0 values
  ([\#355](https://github.com/r-dbi/RPostgres/issues/355)) and generates
  typed `NULL` expressions for `NA` values
  ([\#357](https://github.com/r-dbi/RPostgres/issues/357)).
- The `SET DATESTYLE` query sent after connecting uses quotes for
  compatibility with CockroachDB
  ([\#360](https://github.com/r-dbi/RPostgres/issues/360)).

### Internal

- [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
  executes initial queries with `immediate = TRUE`
  ([\#346](https://github.com/r-dbi/RPostgres/issues/346)).
- Check Postgres starting from version 10 on GitHub Actions
  ([\#368](https://github.com/r-dbi/RPostgres/issues/368)).
- Fix build on Ubuntu 16.04
  ([\#352](https://github.com/r-dbi/RPostgres/issues/352)).
- Mention `libssl-dev` in `configure` script
  ([\#350](https://github.com/r-dbi/RPostgres/issues/350)).

## RPostgres 1.4.1 (2021-09-26)

### Bug fixes

- Avoid crash by dereferencing 0-size vector
  ([\#343](https://github.com/r-dbi/RPostgres/issues/343)).

## RPostgres 1.4.0 (2021-09-25)

### Features

- [`Redshift()`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md)
  connections now adhere to almost all of the DBI specification when
  connecting to a Redshift cluster. BLOBs are not supported on Redshift,
  and there are limitations with enumerating temporary and persistent
  tables ([\#215](https://github.com/r-dbi/RPostgres/issues/215),
  [\#326](https://github.com/r-dbi/RPostgres/issues/326)).
- [`dbBegin()`](https://dbi.r-dbi.org/reference/transactions.html),
  [`dbCommit()`](https://dbi.r-dbi.org/reference/transactions.html) and
  [`dbRollback()`](https://dbi.r-dbi.org/reference/transactions.html)
  gain `name` argument to support savepoints. An unnamed transaction
  must be started beforehand
  ([\#13](https://github.com/r-dbi/RPostgres/issues/13)).
- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  uses a transaction
  ([\#307](https://github.com/r-dbi/RPostgres/issues/307)).
- [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  gains `immediate` argument. Multiple queries (separated by semicolons)
  can be passed in this mode, query parameters are not supported
  ([\#272](https://github.com/r-dbi/RPostgres/issues/272)).
- `dbConnect(check_interrupts = TRUE)` now aborts a running query faster
  and more reliably when the user signals an interrupt, e.g. by pressing
  Ctrl+C ([\#336](https://github.com/r-dbi/RPostgres/issues/336)).
- [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  gains `copy` argument. If set to `TRUE`, data is imported via
  `COPY name FROM STDIN`
  ([\#241](https://github.com/r-dbi/RPostgres/issues/241),
  [@hugheylab](https://github.com/hugheylab)).
- Postgres `NOTICE` messages are now forwarded as proper R messages and
  can be captured and suppressed
  ([\#208](https://github.com/r-dbi/RPostgres/issues/208)).

### Bug fixes

- [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  converts timestamp values to input time zone, used when writing tables
  to Redshift ([\#325](https://github.com/r-dbi/RPostgres/issues/325)).

### Internal

- Skip timestamp tests on i386
  ([\#318](https://github.com/r-dbi/RPostgres/issues/318)).
- [`dbSendQuery()`](https://dbi.r-dbi.org/reference/dbSendQuery.html)
  and
  [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  use single dispatch
  ([\#320](https://github.com/r-dbi/RPostgres/issues/320)).
- [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  default to `copy = NULL`, this translates to `TRUE` for
  [`Postgres()`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  and `FALSE` for
  [`Redshift()`](https://rpostgres.r-dbi.org/dev/reference/Redshift.md)
  connections ([\#329](https://github.com/r-dbi/RPostgres/issues/329)).

### Documentation

- Order help topics on pkgdown site.
- Use `@examplesIf` in method documentation.
- Document when `field.types` is used in
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  ([\#206](https://github.com/r-dbi/RPostgres/issues/206)).
- Document setting the tablespace before writing a table
  ([\#246](https://github.com/r-dbi/RPostgres/issues/246)).
- Tweak error message for named `params` argument to
  [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html)
  ([\#266](https://github.com/r-dbi/RPostgres/issues/266)).

## RPostgres 1.3.3 (2021-07-05)

- Fix `dbConnect(check_interrupts = TRUE)` on Windows
  ([\#244](https://github.com/r-dbi/RPostgres/issues/244),
  [@zozlak](https://github.com/zozlak)).
- Windows: update to libpq 13.2.0 and add UCRT support
  ([\#309](https://github.com/r-dbi/RPostgres/issues/309),
  [@jeroen](https://github.com/jeroen)).

## RPostgres 1.3.2 (2021-04-12)

- Remove BH dependency by inlining the header files
  ([\#300](https://github.com/r-dbi/RPostgres/issues/300)).
- Use Autobrew if libpq is older than version 12
  ([\#294](https://github.com/r-dbi/RPostgres/issues/294),
  [@jeroen](https://github.com/jeroen)).
- [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) now
  issues `SET datestyle to iso, mdy` to avoid translation errors for
  datetime values with databases configured differently
  ([\#287](https://github.com/r-dbi/RPostgres/issues/287),
  [@baderstine](https://github.com/baderstine)).

## RPostgres 1.3.1 (2021-01-19)

### Bug fixes

- `Inf`, `-Inf` and `NaN` values are returned correctly on Windows
  ([\#267](https://github.com/r-dbi/RPostgres/issues/267)).
- Fix behavior with invalid time zone
  ([\#284](https://github.com/r-dbi/RPostgres/issues/284),
  [@ateucher](https://github.com/ateucher)).

### Internal

- [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
  defaults to `timezone_out = NULL`, this means to use `timezone`.
- `FORCE_AUTOBREW` environment variable enforces use of `autobrew` in
  `configure` ([\#283](https://github.com/r-dbi/RPostgres/issues/283),
  [@jeroen](https://github.com/jeroen)).
- Fix `configure` on macOS, small tweaks
  ([\#282](https://github.com/r-dbi/RPostgres/issues/282),
  [\#283](https://github.com/r-dbi/RPostgres/issues/283),
  [@jeroen](https://github.com/jeroen)).
- Fix `configure` script, remove `$()` not reliably detected by
  `checkbashisms`.
- `configure` uses a shell script and no longer forwards to
  `src/configure.bash`
  ([\#265](https://github.com/r-dbi/RPostgres/issues/265)).

## RPostgres 1.3.0 (2021-01-05)

- [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) gains
  `timezone_out` argument, the default `NULL` means to use `timezone`
  ([\#222](https://github.com/r-dbi/RPostgres/issues/222)).
- [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  now quotes difftime values as `interval`
  ([\#270](https://github.com/r-dbi/RPostgres/issues/270)).
- New
  [`postgresWaitForNotify()`](https://rpostgres.r-dbi.org/dev/reference/postgresWaitForNotify.md)
  adds `LISTEN/NOTIFY` support
  ([\#237](https://github.com/r-dbi/RPostgres/issues/237),
  [@lentinj](https://github.com/lentinj)).

### Bug fixes

- `Inf`, `-Inf` and `NaN` values are returned correctly on Windows
  ([\#267](https://github.com/r-dbi/RPostgres/issues/267)).
- `DATETIME` values (=without time zone) and `DATETIMETZ` values (=with
  time zone) are returned correctly
  ([\#190](https://github.com/r-dbi/RPostgres/issues/190),
  [\#205](https://github.com/r-dbi/RPostgres/issues/205),
  [\#229](https://github.com/r-dbi/RPostgres/issues/229)), also if they
  start before 1970
  ([\#221](https://github.com/r-dbi/RPostgres/issues/221)).

### Internal

- `configure` uses a shell script and no longer forwards to
  `src/configure.bash`
  ([\#265](https://github.com/r-dbi/RPostgres/issues/265)).
- Switch to GitHub Actions
  ([\#268](https://github.com/r-dbi/RPostgres/issues/268), thanks
  [@ankane](https://github.com/ankane)).
- Now imports the lubridate package.

## RPostgres 1.2.1 (2020-09-28)

- Gains new `Redshift` driver for connecting to Redshift databases.
  Redshift databases behave almost identically to Postgres so this
  driver allows downstream packages to distinguish between the two
  ([\#258](https://github.com/r-dbi/RPostgres/issues/258)).
- Datetime values are now passed to the database using an unambiguous
  time zone format
  ([\#255](https://github.com/r-dbi/RPostgres/issues/255),
  [@imlijunda](https://github.com/imlijunda)).
- Document
  [`Postgres()`](https://rpostgres.r-dbi.org/dev/reference/Postgres.md)
  together with
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
  ([\#242](https://github.com/r-dbi/RPostgres/issues/242)).
- Windows: update libpq to 12.2.0.

## RPostgres 1.2.0 (2019-12-18)

### Communication with the database

- Breaking: Translate floating-point values to `DOUBLE PRECISION` by
  default ([\#194](https://github.com/r-dbi/RPostgres/issues/194)).
- Avoid aggressive rounding when passing numeric values to the database
  ([\#184](https://github.com/r-dbi/RPostgres/issues/184)).
- Avoid adding extra spaces for numerics
  ([\#216](https://github.com/r-dbi/RPostgres/issues/216)).
- Column names and error messages are UTF-8 encoded
  ([\#172](https://github.com/r-dbi/RPostgres/issues/172)).
- `dbWriteTable(copy = FALSE)`,
  [`sqlData()`](https://dbi.r-dbi.org/reference/sqlData.html) and
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  now work for character columns
  ([\#209](https://github.com/r-dbi/RPostgres/issues/209)), which are
  always converted to UTF-8.

### New features

- Add `timezone` argument to
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
  ([\#187](https://github.com/r-dbi/RPostgres/issues/187),
  [@trafficonese](https://github.com/trafficonese)).
- Implement
  [`dbGetInfo()`](https://dbi.r-dbi.org/reference/dbGetInfo.html) for
  the driver and the connection object.
- [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) gains
  `check_interrupts` argument that allows interrupting execution safely
  while waiting for query results to be ready
  ([\#193](https://github.com/r-dbi/RPostgres/issues/193),
  [@zozlak](https://github.com/zozlak)).
- [`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html)
  also handles unquoted identifiers of the form `table` or
  `schema.table`, for compatibility with dbplyr. In addition, a
  `catalog` component is supported for quoting and unquoting with
  [`Id()`](https://dbi.r-dbi.org/reference/Id.html).
- [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  available for `"character"`
  ([\#209](https://github.com/r-dbi/RPostgres/issues/209)).
- Windows: update libpq to 11.1.0.
- Fulfill CII badge requirements
  ([\#227](https://github.com/r-dbi/RPostgres/issues/227),
  [@TSchiefer](https://github.com/TSchiefer)).

### Bug fixes

- Hide unused symbols in shared library
  ([\#230](https://github.com/r-dbi/RPostgres/issues/230),
  [@troels](https://github.com/troels)).
- Fix partial argument matching in
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  (r-dbi/DBI#249).
- Fix binding for whole numbers and `POSIXt` timestamps
  ([\#191](https://github.com/r-dbi/RPostgres/issues/191)).

### Internal

- `sqlData(copy = FALSE)` now uses
  [`dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  ([\#209](https://github.com/r-dbi/RPostgres/issues/209)).
- Add tests for
  [`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html)
  ([\#220](https://github.com/r-dbi/RPostgres/issues/220),
  [@baileych](https://github.com/baileych)).
- Improved tests for numerical precision
  ([\#203](https://github.com/r-dbi/RPostgres/issues/203),
  [@harvey131](https://github.com/harvey131)).
- Fix test: change from `REAL` to `DOUBLE PRECISION`
  ([\#204](https://github.com/r-dbi/RPostgres/issues/204),
  [@harvey131](https://github.com/harvey131)).
- Implement
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  for own connection class, don’t hijack base class implementation
  (r-dbi/RMariaDB#119).
- Avoid including the call in errors.
- Align `DbResult` and other classes with RSQLite and RMariaDB.

## RPostgres 1.1.3 (2019-12-07)

- Replace `std::mem_fn()` by `boost::mem_fn()` which works for older
  compilers.

## RPostgres 1.1.2 (2019-12-03)

- Replace `std::mem_fun_ref()` by `std::mem_fn()`.

## RPostgres 1.1.1 (2018-05-05)

- Add support for `bigint` argument to
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html),
  supported values are `"integer64"`, `"integer"`, `"numeric"` and
  `"character"`. Large integers are returned as values of that type
  (r-dbi/DBItest#133).
- Data frames resulting from a query always have unique non-empty column
  names (r-dbi/DBItest#137).
- New arguments `temporary` and `fail_if_missing` (default: `TRUE`) to
  [`dbRemoveTable()`](https://dbi.r-dbi.org/reference/dbRemoveTable.html)
  (r-dbi/DBI#141, r-dbi/DBI#197).
- Using
  [`dbCreateTable()`](https://dbi.r-dbi.org/reference/dbCreateTable.html)
  and
  [`dbAppendTable()`](https://dbi.r-dbi.org/reference/dbAppendTable.html)
  internally (r-dbi/DBI#74).
- The `field.types` argument to
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  now must be named.
- Using `current_schemas(true)` also in
  [`dbListObjects()`](https://dbi.r-dbi.org/reference/dbListObjects.html)
  and
  [`dbListTables()`](https://dbi.r-dbi.org/reference/dbListTables.html),
  for consistency with
  [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html).
  Objects from the `pg_catalog` schema are still excluded.
- [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
  doesn’t list fields from tables found in the `pg_catalog` schema.
- The
  [`dbListFields()`](https://dbi.r-dbi.org/reference/dbListFields.html)
  method now works correctly if the `name` argument is a quoted
  identifier or of class `Id`, and throws an error if the table is not
  found (r-dbi/DBI#75).
- Implement [`format()`](https://rdrr.io/r/base/format.html) method for
  `SqliteConnection` (r-dbi/DBI#163).
- Reexporting [`Id()`](https://dbi.r-dbi.org/reference/Id.html),
  [`DBI::dbIsReadOnly()`](https://dbi.r-dbi.org/reference/dbIsReadOnly.html)
  and
  [`DBI::dbCanConnect()`](https://dbi.r-dbi.org/reference/dbCanConnect.html).
- Now imports DBI 1.0.0.

## RPostgres 1.1.0 (2018-04-04)

- Breaking change:
  [`dbGetException()`](https://dbi.r-dbi.org/reference/dbGetException.html)
  is no longer reexported from DBI.
- Make “typname” information available after
  [`dbFetch()`](https://dbi.r-dbi.org/reference/dbFetch.html) and
  [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html).
  Values of unknown type are returned as character vector of class
  `"pq_xxx"`, where `"xxx"` is the “typname” returned from PostgreSQL.
  In particular, `JSON` and `JSONB` values now have class `"pq_json"`
  and `"pq_jsonb"`, respectively. The return value of
  [`dbColumnInfo()`](https://dbi.r-dbi.org/reference/dbColumnInfo.html)
  gains new columns `".oid"` (`integer`), `". known"` (`logical`) and
  `".typname"` (`character`)
  ([\#114](https://github.com/r-dbi/RPostgres/issues/114),
  [@etiennebr](https://github.com/etiennebr)).
- Values of class `"integer64"` are now supported for
  [`dbWriteTable()`](https://dbi.r-dbi.org/reference/dbWriteTable.html)
  and [`dbBind()`](https://dbi.r-dbi.org/reference/dbBind.html)
  ([\#178](https://github.com/r-dbi/RPostgres/issues/178)).
- Schema support, as specified by DBI:
  [`dbListObjects()`](https://dbi.r-dbi.org/reference/dbListObjects.html),
  [`dbUnquoteIdentifier()`](https://dbi.r-dbi.org/reference/dbUnquoteIdentifier.html)
  and [`Id()`](https://dbi.r-dbi.org/reference/Id.html).
- Names in the `x` argument to
  [`dbQuoteIdentifier()`](https://dbi.r-dbi.org/reference/dbQuoteIdentifier.html)
  are preserved in the output (r-dbi/DBI#173).
- All generics defined in DBI (e.g.,
  [`dbGetQuery()`](https://dbi.r-dbi.org/reference/dbGetQuery.html)) are
  now exported, even if the package doesn’t provide a custom
  implementation
  ([\#168](https://github.com/r-dbi/RPostgres/issues/168)).
- Replace non-portable `timegm()` with private implementation.
- Correct reference to RPostgreSQL package
  ([\#165](https://github.com/r-dbi/RPostgres/issues/165),
  [@ClaytonJY](https://github.com/ClaytonJY)).

## RPostgres 1.0-4 (2017-12-20)

- Only call `PQcancel()` if the query hasn’t completed, fixes
  transactions on Amazon Redshift
  ([\#159](https://github.com/r-dbi/RPostgres/issues/159),
  [@mmuurr](https://github.com/mmuurr)).
- Fix installation on macOS.
- Check libpq version in configure script (need at least 9.0).
- Fix UBSAN warning: reference binding to null pointer
  ([\#156](https://github.com/r-dbi/RPostgres/issues/156)).
- Fix rchk warning: PROTECT internal temporary SEXP objects
  ([\#157](https://github.com/r-dbi/RPostgres/issues/157)).
- Fix severe memory leak when fetching results
  ([\#154](https://github.com/r-dbi/RPostgres/issues/154)).

## RPostgres 1.0-3 (2017-12-01)

Initial release, compliant to the DBI specification.

- Test almost all test cases of the DBI specification.
- Fully support parametrized queries.
- Spec-compliant transactions.
- 64-bit integers are now supported through the `bit64` package. This
  also means that numeric literals (as in `SELECT 1`) are returned as
  64-bit integers. The `bigint` argument to
  [`dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html) allows
  overriding the data type on a per-connection basis.
- Correct handling of DATETIME and TIME columns.
- New default `row.names = FALSE`.
