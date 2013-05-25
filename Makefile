#!/usr/bin/make -f
#
#   Copyright information
#
#	Copyright (C) 2002-2012 Jari Aalto
#
#   License
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program. If not, see <http://www.gnu.org/licenses/>.

ifneq (,)
This makefile requires GNU Make.
endif

PACKAGE		= copyright-update
DESTDIR		=
prefix		= /usr
exec_prefix	= $(prefix)
man_prefix	= $(prefix)/share
mandir		= $(man_prefix)/man
bindir		= $(exec_prefix)/bin
sharedir	= $(prefix)/share

BINDIR		= $(DESTDIR)$(bindir)
DOCDIR		= $(DESTDIR)$(sharedir)/doc/$(PACKAGE)
LOCALEDIR	= $(DESTDIR)$(sharedir)/locale
SHAREDIR	= $(DESTDIR)$(sharedir)/$(PACKAGE)
LIBDIR		= $(DESTDIR)$(prefix)/lib/$(PACKAGE)
SBINDIR		= $(DESTDIR)$(exec_prefix)/sbin
ETCDIR		= $(DESTDIR)/etc/$(PACKAGE)

# 1 = regular, 5 = conf, 6 = games, 8 = daemons
MANDIR		= $(DESTDIR)$(mandir)
MANDIR1		= $(MANDIR)/man1
MANDIR5		= $(MANDIR)/man5
MANDIR6		= $(MANDIR)/man6
MANDIR8		= $(MANDIR)/man8

TAR		= tar
TAR_OPT_NO	= --exclude='.build'	 \
		  --exclude='.sinst'	 \
		  --exclude='.inst'	 \
		  --exclude='tmp'	 \
		  --exclude='*.bak'	 \
		  --exclude='*[~\#]'	 \
		  --exclude='.\#*'	 \
		  --exclude='CVS'	 \
		  --exclude='.svn'	 \
		  --exclude='.git'	 \
		  --exclude='.bzr'	 \
		  --exclude='*.tar*'	 \
		  --exclude='*.tgz'

INSTALL		= /usr/bin/install
INSTALL_BIN	= $(INSTALL) -m 755
INSTALL_DATA	= $(INSTALL) -m 644
INSTALL_SUID	= $(INSTALL) -m 4755

DIST_DIR	= ../build-area
DATE		= `date +"%Y.%m%d"`
VERSION		= $(DATE)
RELEASE		= $(PACKAGE)-$(VERSION)

BIN		= $(PACKAGE)
PL_SCRIPT	= bin/$(BIN).pl

INSTALL_OBJS_BIN   = $(PL_SCRIPT)
INSTALL_OBJS_DOC   = README COPYING
INSTALL_OBJS_MAN   = bin/*.1

all:
	@echo "Nothing to compile."
	@echo "Try 'make help' or 'make -n DESTDIR= prefix=/usr/local install'"

# Rule: help - display Makefile rules
help:
	@grep "^# Rule:" Makefile | sort

# Rule: clean - remove temporary files
clean:
	# clean
	-rm -f *[#~] *.\#* \
	*.x~~ pod*.tmp

	rm -rf tmp

distclean: clean

realclean: clean

dist-git: test doc
	rm -f $(DIST_DIR)/$(RELEASE)*

	git archive --format=tar --prefix=$(RELEASE)/ master | \
	gzip --best > $(DIST_DIR)/$(RELEASE).tar.gz

	chmod 644 $(DIST_DIR)/$(RELEASE).tar.gz

	tar -tvf $(DIST_DIR)/$(RELEASE).tar.gz | sort -k 5
	ls -la $(DIST_DIR)/$(RELEASE).tar.gz

# The "gt" is maintainer's program frontend to Git
# Rule: dist-snap - [maintainer] release snapshot from Git repository
dist-snap: test doc
	@echo gt tar -q -z -p $(PACKAGE) -c -D master

# Rule: dist - [maintainer] release from Git repository
dist: dist-git

dist-ls:
	@ls -1tr $(DIST_DIR)/$(PACKAGE)*

# Rule: dist - [maintainer] list of release files
ls: dist-ls

bin/$(PACKAGE).1: $(PL_SCRIPT)
	$(PERL) $< --help-man > $@
	@-rm -f *.x~~ pod*.tmp

doc/manual/$(PACKAGE).html: $(PL_SCRIPT)
	$(PERL) $< --help-html > $@
	@-rm -f *.x~~ pod*.tmp

doc/manual/$(PACKAGE).txt: $(PL_SCRIPT)
	$(PERL) $< --help > $@
	@-rm -f *.x~~ pod*.tmp

doc/conversion/index.html: doc/conversion/index.txt
	perl -S t2html.pl --Auto-detect --Out --print-url $<

# Rule: man - Generate or update manual page
man: bin/$(PACKAGE).1

html: doc/manual/$(PACKAGE).html

txt: doc/manual/$(PACKAGE).txt

# Rule: doc - Generate or update all documentation
doc: man html txt

# Rule: perl-test - Check program syntax
perl-test:
	# perl-test - Check syntax
	perl -cw $(PL_SCRIPT)
	podchecker $(PL_SCRIPT)

# Rule: test - Run tests
test: perl-test

install-doc:
	# Rule install-doc - Install documentation
	$(INSTALL_BIN) -d $(DOCDIR)

	[ ! "$(INSTALL_OBJS_DOC)" ] || \
		$(INSTALL_DATA) $(INSTALL_OBJS_DOC) $(DOCDIR)

	$(TAR) -C doc $(TAR_OPT_NO) --create --file=- . | \
	$(TAR) -C $(DOCDIR) --extract --file=-

install-man: man
	# install-man - Install manual pages
	$(INSTALL_BIN) -d $(MANDIR1)
	$(INSTALL_DATA) $(INSTALL_OBJS_MAN) $(MANDIR1)

install-bin:
	# install-bin - Install programs
	$(INSTALL_BIN) -d $(BINDIR)
	for f in $(INSTALL_OBJS_BIN); \
	do \
		dest=$$(basename $$f | sed -e 's/\.pl$$//' -e 's/\.py$$//' ); \
		$(INSTALL_BIN) $$f $(BINDIR)/$$dest; \
	done

# Rule: install - Standard install
install: install-bin install-man install-doc

# Rule: install-test - for Maintainer only
install-test:
	rm -rf tmp
	make DESTDIR=`pwd`/tmp prefix=/usr install
	find tmp | sort

.PHONY: clean distclean realclean
.PHONY: install install-bin install-man
.PHONY: all man doc test install-test perl-test
.PHONY: dist dist-git dist-ls ls

# End of file
