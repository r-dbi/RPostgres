Resubmission upon CRAN's request.

- Version 1.0-2 now runs tests and examples if a default PostgreSQL connection is available (via env vars listed in <https://www.postgresql.org/docs/9.6/static/libpq-envars.html>), and silently succeeds if not.
- Version 1.0-1 includes an improved building procedure on OS X, compared to 1.0. This has been contributed after I submitted 1.0, sorry for the noise.
- Added links to PostgreSQL, and a brief description.

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
