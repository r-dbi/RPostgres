Minor release for compatibility with older compilers.

## Test environments
* local ubuntu install, R 3.6.1
* ubuntu 16.04 (on travis-ci), R 3.6.1, devel, oldrel, 3.2
* windows (on appveyor), R 3.6.1
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* We link libpq (and libcrypto) statically on Windows, hence the size.

## Downstream packages

Not checked.
