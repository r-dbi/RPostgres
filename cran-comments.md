Fix for UBSAN and rchk erros, a memory leak, and compatibility problems with Amazon RedShift.

## Test environments
* local ubuntu install, R 3.4.3
* ubuntu 14.04 (on travis-ci), R 3.4.3, devel, oldrel, 3.2
* windows (on appveyor), R 3.4.3
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

* We link libpq (and libcrypto) statically on Windows, hence the size.
