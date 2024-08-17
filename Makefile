PROGNAME ?= mux
PREFIX   ?= /usr
BINDIR   ?= $(PREFIX)/bin
SHAREDIR ?= $(PREFIX)/share

.PHONY: install
install: src/$(PROGNAME).sh
	install -d $(BINDIR)
	install -m755 src/$(PROGNAME).sh $(BINDIR)/$(PROGNAME)
	install -Dm644 LICENSE -t $(SHAREDIR)/licenses/$(PROGNAME)

.PHONY: uninstall
uninstall:
	rm $(BINDIR)/$(PROGNAME)
	rm -rf $(SHAREDIR)/licenses/$(PROGNAME)
