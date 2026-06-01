CC := gcc
CFLAGS := -O2 -Wall -Wextra -Wpedantic -std=c11

sample-project: main.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f sample-project
