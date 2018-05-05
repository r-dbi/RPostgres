Minor release for compatibility with DBI 1.0.0.

## Test environments
* local ubuntu install, R 3.4.4
* ubuntu 14.04 (on travis-ci), R 3.4.4, devel, oldrel, 3.2
* windows (on appveyor), R 3.4.4
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* We link libpq (and libcrypto) statically on Windows, hence the size.

## Downstream packages

Tested RGreenplum and sf, no error.
