EMACS ?= emacs
EASK ?= eask

compile:
	$(EASK) compile

all: autoloads $(ELCS)

autoloads:
	$(EASK) generate autoloads

clean:
	$(EASK) clean all

test: clean all
	$(EASK) test ert ./tests/php-mode-test.el

.PHONY: all autoloads clean test
