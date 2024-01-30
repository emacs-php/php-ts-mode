;;; php-ts-mode-tests.el --- Tests for Tree-sitter-based PHP mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023 Free Software Foundation, Inc.
;; Copyright (C) 2023  Friends of Emacs-PHP development

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)
(require 'ert-x)
(require 'treesit)

(declare-function treesit-install-language-grammar "treesit.c")

(if (and (treesit-available-p) (boundp 'treesit-language-source-alist))
    (unless (treesit-language-available-p 'php)
      (treesit-install-language-grammar 'php)))

(ert-deftest php-ts-mode-test-indentation ()
  (skip-unless (treesit-ready-p 'php))
  (ert-test-erts-file (ert-resource-file "indent.erts")))

; FIXME: implement basic movements
;(ert-deftest php-ts-mode-test-movement ()
;  (skip-unless (treesit-ready-p 'php))
; (ert-test-erts-file (ert-resource-file "movement.erts")))

(provide 'php-ts-mode-tests)
;;; php-ts-mode-tests.el ends here
