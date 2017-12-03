Resubmission upon CRAN's request.

- Added links to PostgreSQL, and a brief description.
- Examples cannot be made runnable, because at least WinBuilder seems to be lacking the necessary environment settings, see the first few entries in <https://www.postgresql.org/docs/9.6/static/libpq-envars.html>. Instead, these settings are available (on WinBuilder) under `$POSTGRES_HOST`, `$POSTGRES_PORT`, `$POSTGRES_USER`, `$POSTGRES_PASSWD`, and `$POSTGRES_DATABASE`. I'd rather avoid fetching configuration from these variables. Would you consider setting up the environment variables as required by libpq on CRAN and WinBuilder?

## Test environments
* local ubuntu install, R 3.4.2
* ubuntu 14.04 (on travis-ci), R 3.4.2, devel, oldrel, 3.2
* windows (on appveyor), R 3.4.2
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 2 notes

* This is a new release.

* We link libpq (and libcrypto) statically on Windows, hence the size.

## Reverse dependencies

This is a new release, so there are no reverse dependencies.
