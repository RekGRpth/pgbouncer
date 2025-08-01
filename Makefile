
include config.mak

bin_PROGRAMS = pgbouncer

pgbouncer_SOURCES = \
	src/admin.c \
	src/client.c \
	src/dnslookup.c \
	src/hba.c \
	src/janitor.c \
	src/loader.c \
	src/messages.c \
	src/main.c \
	src/objects.c \
	src/pam.c \
	src/ldapauth.c \
	src/pktbuf.c \
	src/pooler.c \
	src/proto.c \
	src/prepare.c \
	src/sbuf.c \
	src/scram.c \
	src/server.c \
	src/stats.c \
	src/system.c \
	src/takeover.c \
	src/util.c \
	src/varcache.c \
	src/common/base64.c \
	src/common/bool.c \
	src/common/pgstrcasecmp.c \
	src/common/saslprep.c \
	src/common/scram-common.c \
	src/common/unicode_norm.c \
	src/common/wchar.c \
	include/admin.h \
	include/bouncer.h \
	include/client.h \
	include/dnslookup.h \
	include/hba.h \
	include/iobuf.h \
	include/janitor.h \
	include/loader.h \
	include/messages.h \
	include/objects.h \
	include/pam.h \
	include/ldapauth.h \
	include/pktbuf.h \
	include/pooler.h \
	include/proto.h \
	include/prepare.h \
	include/sbuf.h \
	include/scram.h \
	include/server.h \
	include/stats.h \
	include/system.h \
	include/takeover.h \
	include/util.h \
	include/varcache.h \
	include/common/base64.h \
	include/common/builtins.h \
	include/common/pg_wchar.h \
	include/common/postgres_compat.h \
	include/common/protocol.h \
	include/common/saslprep.h \
	include/common/scram-common.h \
	include/common/unicode_combining_table.h \
	include/common/unicode_norm.h \
	include/common/unicode_norm_table.h \
	include/common/uthash.h \
	include/common/uthash_lowercase.h

pgbouncer_CPPFLAGS = -Iinclude $(CARES_CFLAGS) $(LIBEVENT_CFLAGS) $(TLS_CPPFLAGS) $(LDAP_CFLAGS)

# include libusual sources directly
AM_FEATURES = libusual
pgbouncer_EMBED_LIBUSUAL = 1

# docs to install as-is
dist_doc_DATA = README.md NEWS.md \
	etc/pgbouncer-minimal.ini \
	etc/pgbouncer.ini \
	etc/pgbouncer.service \
	etc/pgbouncer.socket \
	etc/userlist.txt

DISTCLEANFILES = config.mak config.status lib/usual/config.h config.log

#DIST_SUBDIRS = doc test
#dist_man_MANS = doc/pgbouncer.1 doc/pgbouncer.5

pgbouncer_LDFLAGS := $(TLS_LDFLAGS)
pgbouncer_LDADD := $(CARES_LIBS) $(LIBEVENT_LIBS) $(TLS_LIBS) $(LIBS)
LIBS :=

#
# win32
#

EXTRA_pgbouncer_SOURCES = win32/win32support.c win32/win32support.h win32/win32ver.rc
EXTRA_PROGRAMS = pgbevent
ifeq ($(PORTNAME),win32)
pgbouncer_CPPFLAGS += -Iwin32
pgbouncer_SOURCES += $(EXTRA_pgbouncer_SOURCES)
bin_PROGRAMS += pgbevent
endif

pgbevent_SOURCES = win32/pgbevent.c win32/eventmsg.rc \
		   win32/eventmsg.mc win32/MSG00001.bin
pgbevent_EXT = .dll
pgbevent_LINK = $(CC) -shared -Wl,--export-all-symbols -Wl,--add-stdcall-alias -o $@ $^

# .rc->.o
AM_LANGUAGES = RC
AM_LANG_RC_SRCEXTS = .rc
AM_LANG_RC_COMPILE = $(WINDRES) $< -o $@ --include-dir=$(srcdir)/win32 --include-dir=lib
AM_LANG_RC_LINK = false

#
# now load antimake
#

# disable dist target from antimake
AM_DIST_DEFAULT =

USUAL_DIR = lib

abs_top_srcdir ?= $(CURDIR)
include $(abs_top_srcdir)/lib/mk/antimake.mk

config.mak:
	@echo "Please run ./configure"
	@exit 1

#
# dist
# (adapted from PostgreSQL)
#

distdir = $(PACKAGE_TARNAME)-$(PACKAGE_VERSION)
PG_GIT_REVISION = HEAD
GIT = git

EXTRA_DIST = config.guess config.sub configure install-sh lib/usual/config.h.in

dist: $(distdir).tar.gz

$(PACKAGE_TARNAME)-$(PACKAGE_VERSION).tar.gz:
	$(GIT) -C $(srcdir) -c core.autocrlf=false archive --format tar.gz -9 --prefix $(distdir)/ $(PG_GIT_REVISION) -o $(abs_top_builddir)/$@ $(foreach file,$(EXTRA_DIST),--prefix $(distdir)/$(dir $(file)) --add-file=$(file)) --prefix $(distdir)/

#
# test
#

PYTEST = $(shell command -v pytest || echo '$(PYTHON) -m pytest')

CONCURRENCY = auto

check: all
	etc/optscan.sh
	if [ $(CONCURRENCY) = 1 ]; then \
		PYTHONIOENCODING=utf8 $(PYTEST); \
	else \
		PYTHONIOENCODING=utf8 $(PYTEST) -n $(CONCURRENCY); \
	fi
	$(MAKE) -C test check

w32zip = $(PACKAGE_TARNAME)-$(PACKAGE_VERSION)-windows-$(host_cpu).zip
zip: $(w32zip)

$(w32zip): pgbouncer.exe pgbevent.dll etc/pgbouncer.ini etc/userlist.txt README.md COPYRIGHT
	rm -rf $(basename $@)
	mkdir $(basename $@)
	cp $^ $(basename $@)
	$(STRIP) $(addprefix $(basename $@)/,$(filter %.exe %.dll,$(^F)))
	zip -MM $@ $(addprefix $(basename $@)/,$(filter %.exe %.dll,$(^F)))
# NB: zip -l for text files for end-of-line conversion
	zip -MM -l $@ $(addprefix $(basename $@)/,$(filter-out %.exe %.dll,$(^F)))

.PHONY: tags
tags:
	ctags src/*.c include/*.h lib/usual/*.[ch] lib/usual/*/*.[ch]

#htmls:
#	for f in *.md doc/*.md; do \
#		mkdir -p html && $(PANDOC) $$f -o html/`basename $$f`.html; \
#	done

doc/pgbouncer.1 doc/pgbouncer.5:
	$(MAKE) -C doc $(@F)

lint:
	flake8

UNCRUSTIFY_FILES = include/*.h src/*.c test/*.c \
		lib/test/*.c lib/usual/*.c lib/usual/crypto/*.c lib/usual/hashing/*.c lib/usual/tls/*.c \
		lib/test/*.h lib/usual/*.h lib/usual/crypto/*.h lib/usual/hashing/*.h lib/usual/tls/*.h

format-check: uncrustify
	git diff-tree --check `git hash-object -t tree /dev/null` HEAD
	black --check --diff .
	isort --check --diff .
	./uncrustify -c uncrustify.cfg --check -L WARN $(UNCRUSTIFY_FILES)

format: uncrustify
	$(MAKE) format-c
	$(MAKE) format-python

format-python: uncrustify
	black .
	isort .

format-c: uncrustify
	./uncrustify -c uncrustify.cfg --replace --no-backup -L WARN $(UNCRUSTIFY_FILES)

UNCRUSTIFY_VERSION=0.77.1

uncrustify:
	temp=$$(mktemp -d) \
		&& cd $$temp \
		&& curl -L https://github.com/uncrustify/uncrustify/archive/refs/tags/uncrustify-$(UNCRUSTIFY_VERSION).tar.gz --output uncrustify.tar.gz \
		&& tar xzf uncrustify.tar.gz \
		&& cd uncrustify-uncrustify-$(UNCRUSTIFY_VERSION) \
		&& mkdir -p build \
		&& cd build \
		&& cmake .. \
		&& $(MAKE) \
		&& cp uncrustify $(CURDIR)/uncrustify
