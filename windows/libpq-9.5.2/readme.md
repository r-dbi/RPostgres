Library was built from patched msys2 sources with:

```sh
../postgresql-9.5.2/configure \
  --disable-thread-safety \
  --with-openssl \
  --enable-integer-datetimes \
  --disable-nls \
  --with-ldap \
  --with-libxml \
  --with-libxslt \
  --with-python \
  --without-perl \
  --with-tcl
```

Note that `--disable-thread-safety` avoids depending on pthread, so the same build can be used with gcc-4-6.3 as gcc-4.9.3.

Unfortunately the standard libpq Makefile does not generate static
libraries. To build `libqp.a`, first run the usualy `make`. Then append file `src/interfaces/libpq/Makefile` with: 

```make
libpq.a: $(OBJS)
  ar rcs $@ $^
```

And then run `make libpq.a`. To link use:

```make
PKG_LIBS= -lpq -lssl -lcrypto -lwsock32 -lsecur32 -lws2_32 -lgdi32 -lcrypt32 -lwldap32
```
