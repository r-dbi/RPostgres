Resubmission to fix UBSAN errors and a memory leak.

## Test environments
* local ubuntu install, R 3.4.3
* ubuntu 14.04 (on travis-ci), R 3.4.2, devel, oldrel, 3.2
* windows (on appveyor), R 3.4.2
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 2 notes

* The severity of the fixed problems suggests an immediate update.

* We link libpq (and libcrypto) statically on Windows, hence the size.
