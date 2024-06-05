CFLAGS+=-std=c99 -pedantic -Wall -Wextra
LDFLAGS+=
LDLIBS+=

BINDIR?=$(DESTDIR)$(PREFIX)/usr/bin

BIN=encode decode

ifeq ($(BUILD),debug)
	CFLAGS+=-Og -g
	LDFLAGS+=-rdynamic
endif

ifeq ($(BUILD),release)
	CFLAGS+=-march=native -O3 -DNDEBUG
endif

ifeq ($(BUILD),profile-generate)
	CFLAGS+=-march=native -O3 -DNDEBUG -fprofile-generate
	LDFLAGS+=-fprofile-generate
endif

ifeq ($(BUILD),profile-use)
	CFLAGS+=-march=native -O3 -DNDEBUG -fprofile-use
endif

ifeq ($(BUILD),profile)
	CFLAGS+=-Og -g -pg
	LDFLAGS+=-rdynamic -pg
endif

.PHONY: all
all: $(BIN)

encode: encode.o libx.o

libx.o: libx.c libx.h

decode: encode
	ln -s $< $@

.PHONY: clean
clean:
	-$(RM) -- *.o $(BIN)

.PHONY: distclean
distclean: clean
	-$(RM) -- *.gcda gmon.out cachegrind.out.* callgrind.out.*

.PHONY: build-pgo
build-pgo:
	$(MAKE) distclean all BUILD=profile-generate
	./encode -f -1 libx.c
	./decode -f libx.c.x libx.c.x.out
	diff libx.c libx.c.x.out
	$(MAKE) clean all BUILD=profile-use
	-$(RM) -- libx.c.x libx.c.x.out

.PHONY: check
check: all
	./encode -f libx.c
	./decode -f libx.c.x libx.c.x.out
	diff libx.c libx.c.x.out
	-$(RM) -- libx.c.x libx.c.x.out

.PHONY: install
install: all
	install -d $(BINDIR)
	install -m 755 x $(BINDIR)
	cp -d decode $(BINDIR)
