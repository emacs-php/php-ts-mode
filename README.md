# php-ts-mode

A Tree-sitter based major mode for editing PHP codes.

> [!NOTE]
> This package is based on Emacs 29's built-in [`treesit`][treesit] and `c-ts-common` features.  
> `php-ts-mode` has been tested with [v0.21.1][] of [tree-sitter-php][].

[treesit]: https://www.gnu.org/software/emacs/manual/html_node/elisp/Language-Grammar.html
[tree-sitter-php]: https://github.com/tree-sitter/tree-sitter-php
[v0.21.1]: https://github.com/tree-sitter/tree-sitter-php/releases/tag/v0.21.1

## How to install

If you haven't installed Tree-sitter yet, please read [How to Get Started with Tree-Sitter - Mastering Emacs][].  At this point, Tree-sitter may be too early for those who cannot compile and install it themselves. You will end up recompiling it with every future update of [tree-sitter-php][].

[How to Get Started with Tree-Sitter - Mastering Emacs]: https://www.masteringemacs.org/article/how-to-get-started-tree-sitter

Package can be installed by running the following command.

```
M-x package-vc-install [RET] https://github.com/emacs-php/php-ts-mode
```

### Configuration

Example configuration that you can put in your `.emacs` file

```
;; Enable variables highlighting
(customize-set-variable 'treesit-font-lock-level 4)

(add-hook 'php-ts-mode-hook (lambda ()
			      ;; Use spaces for indent
			      (setq-local indent-tabs-mode nil)))
```

### Grammer installation

If you don't already have `php-ts-mode` installed, please evaluate the Lisp code below.

```elisp
(add-to-list 'treesit-language-source-alist
             '(php "https://github.com/tree-sitter/tree-sitter-php" "master" "php/src"))
```

Running `M-x treesit-install-language-grammar [RET] php` will compile and install the latest [tree-sitter-php][].

## Settings

### Syntax highlighting

In `php-ts-mode`, syntax elements are classified as follows.

 * **Level 1**: `comment` `definition` `preprocessor`
 * **Level 2**: `keyword` `string` `type`
 * **Level 3**: `function` `constant` `label`
 * **Level 4**: `bracket` `delimiter` `operator` `variables` `this`

By default, up to **Level 3** will be highlighted.

## How to develop

 1. Chekout [tree-sitter-php][] to your computer.
 2. Do `make install`

## Copyright

This code is currently based on [java-ts-mode](https://emba.gnu.org/emacs/emacs/-/blob/master/lisp/progmodes/java-ts-mode.el).

> Copyright (C) 2022-2023 Free Software Foundation, Inc.
> Copyright (C) 2023  Friends of Emacs-PHP development
>
> This program is free software; you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
>
> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.
>
> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <https://www.gnu.org/licenses/>.

There are plans to transfer this project to GNU Emacs, so if you haven't assigned a copyright to the FSF yet, please refer to the [Org-mode contribute guide](https://orgmode.org/worg/org-contribute.html#copyright) and send me an email!
