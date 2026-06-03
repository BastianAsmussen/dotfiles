CC     ?= cc
CFLAGS ?= -std=c23 -Wall -Wextra -O2
PREFIX ?= /usr/local

sample-project: src/main.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: install clean
install: sample-project
	install -Dm755 sample-project $(DESTDIR)$(PREFIX)/bin/sample-project

clean:
	rm -f sample-project
