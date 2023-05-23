EMACS ?= emacs
ELS = php-ts-mode.el
ELS += php-face.el
ELCS = $(ELS:.el=.elc)
AUTOLOADS = php-ts-mode-autoloads.el

%.elc: %.el
	$(EMACS) --batch -L $(ELS) -f batch-byte-compile $<

all: autoloads $(ELCS)

autoloads: $(AUTOLOADS)

$(AUTOLOADS): $(ELS)
	$(EMACS) --batch -L $(ELS) --eval \
	"(let ((user-emacs-directory default-directory)) \
	   (require 'package) \
	   (package-generate-autoloads \"php-ts-mode\" (expand-file-name \".\")))"

clean:
	rm -rf $(ELCS) $(AUTOLOADS) tree-sitter

test: clean all
	$(EMACS) --batch \
		-l php-ts-mode-autoloads.el \
		--eval \
		"(progn \
		  (require 'treesit) \
		  (declare-function treesit-install-language-grammar \"treesit.c\") \
		  (if (and (treesit-available-p) (boundp 'treesit-language-source-alist)) \
		      (unless (treesit-language-available-p 'php) \
		        (add-to-list \
		         'treesit-language-source-alist \
		         '(php . (\"https://github.com/tree-sitter/tree-sitter-php.git\"))) \
		        (treesit-install-language-grammar 'php))))))" \
		-l ./tests/php-ts-mode-tests.el \
		-f ert-run-tests-batch-and-exit

.PHONY: all autoloads clean test
