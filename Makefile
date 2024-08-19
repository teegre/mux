PROGNAME ?= mux
PREFIX   ?= /usr
BINDIR   ?= $(PREFIX)/bin

.PHONY: install
install: src/$(PROGNAME).sh
	install -d $(BINDIR)
	install -m755 src/$(PROGNAME).sh $(BINDIR)/$(PROGNAME)

.PHONY: uninstall
uninstall:
	rm $(BINDIR)/$(PROGNAME)
