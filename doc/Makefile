-include ../config.mak

manpages = pgbouncer.1 pgbouncer.5

dist_man_MANS = $(manpages)

CLEANFILES = pgbouncer_1.md pgbouncer_5.md

# make maintainer-clean removes those
MAINTAINERCLEANFILES = $(manpages)

SUBLOC = doc
abs_top_srcdir ?= $(CURDIR)/..
include $(abs_top_srcdir)/lib/mk/antimake.mk

export PACKAGE_VERSION

pgbouncer.%: pgbouncer_%.md
	$(PANDOC) -s -t man -o $@ $<

pgbouncer_1.md: filter.py frag-usage-man.md usage.md
	$(PYTHON) $^ >$@

pgbouncer_5.md: filter.py frag-config-man.md config.md
	$(PYTHON) $^ >$@

web:
	$(MAKE) -C ../../pgbouncer.github.io
