#include <R_ext/Rdynload.h>

#ifdef _WIN32
#include <windows.h>
#endif

// From http://www.postgresql.org/docs/9.4/static/libpq-connect.html:
// On Windows, there is a way to improve performance if a single database
// connection is repeatedly started and shutdown. Internally, libpq calls
// WSAStartup() and WSACleanup() for connection startup and shutdown,
// respectively. WSAStartup() increments an internal Windows library reference
// count which is decremented by WSACleanup(). When the reference count is just
// one, calling WSACleanup() frees all resources and all DLLs are unloaded.
// This is an expensive operation. To avoid this, an application can manually
// call WSAStartup() so resources will not be freed when the last database
// connection is closed.

void R_init_mypackage(DllInfo *info) {
#ifdef _WIN32
  WSAStartup(MAKEWORD(1, 0), NULL);
#endif
}

void R_unload_mylib(DllInfo *info) {
#ifdef _WIN32
  WSACleanup();
#endif
}
