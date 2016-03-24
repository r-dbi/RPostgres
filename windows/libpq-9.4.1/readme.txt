Library built with:

    --with-openssl \
    --enable-integer-datetimes \
    --disable-nls \
    --with-ldap \
    --with-libxml \
    --with-libxslt \
    --with-python \
    --without-perl \
    --with-tcl \

First run the usualy Make. Because make does not generate static libraries
by default, append file src/interfaces/libpq/Makefile with: 

    libpq_static.a: $(OBJS)
    	ar rcs $@ $^

And then run `make libpq_static.a`. To link use:

PKG_LIBS= -lpq -lssl -lcrypto -lwsock32 -lsecur32 -lws2_32 -lgdi32 -lcrypt32 -lwldap32
