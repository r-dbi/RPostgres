#include <cpp11.hpp>
#include <libpq-fe.h>
#include <libpq/libpq-fs.h>

// Temporary fix for false positive in gcc-12 (fixed in gcc-13)
#if __GNUC__ == 12
/*IGNORE*/ #pragma GCC diagnostic push
/*IGNORE*/ #pragma GCC diagnostic ignored "-Wuse-after-free"
#endif
