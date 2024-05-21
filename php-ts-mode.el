;;; php-ts-mode.el --- Tree-sitter support for PHP   -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023 Free Software Foundation, Inc.
;; Copyright (C) 2023  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 01 Apr 2023
;; URL: https://github.com/emacs-php/php-ts-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; License: GPL-3.0-or-later
;; Keywords: languages, php, tree-sitter

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

;;; Commentary:

;; A Tree-sitter based major mode for editing PHP codes.

;;; Code:
(eval-when-compile
  (require 'cc-mode)
  (require 'cl-lib))
(require 'treesit)
(require 'c-ts-common)
(require 'php nil t)
(require 'php-face nil t)
(require 'php-ts-face nil t)

(declare-function php-base-mode "ext:php")
(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-child "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-search-subtree "treesit.c")

(defcustom php-ts-mode-indent-offset 4
  "Number of spaces for each indentation step in `php-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'php)

(defvar php-ts-mode--syntax-table
  (eval-when-compile
    (let ((table (make-syntax-table)))
      (c-populate-syntax-table table)
      (modify-syntax-entry ?_ "w" table)
      (modify-syntax-entry ?`  "\"" table)
      (modify-syntax-entry ?\" "\"" table)
      (modify-syntax-entry ?#  "< b" table)
      (modify-syntax-entry ?\n "> b" table)
      table)))

(defvar php-ts-mode--indent-rules
  (let ((offset php-ts-mode-indent-offset))
    `((php
       ((node-is "}") parent-bol 0)
       ((node-is ")") parent-bol 0)
       ((node-is "]") parent-bol 0)
       ((node-is "->") parent-bol ,offset)
       ((parent-is "program") column-0 0)
       ((parent-is "comment") parent-bol 1)
       ((parent-is "declaration_list") parent-bol ,offset)
       ;; "compound_statement" contains the body of many statements.
       ;; For example function_definition, foreach_statement, etc.
       ((parent-is "compound_statement") parent-bol ,offset)
       ((parent-is "method_declaration") parent-bol 0)
       ((parent-is "array_creation_expression") parent-bol ,offset)
       ((parent-is "base_clause") parent-bol ,offset)
       ((parent-is "class_interface_clause") parent-bol ,offset)
       ((parent-is "formal_parameters") parent-bol ,offset)
       ((parent-is "arguments") parent-bol ,offset)
       ((parent-is "parenthesized_expression") parent-bol ,offset)
       ((parent-is "binary_expression") parent-bol, 0)
       ((parent-is "switch_block") parent-bol ,offset)
       ((parent-is "case_statement") parent-bol ,offset)
       ((parent-is "default_statement") parent-bol ,offset)
       ((parent-is "assignment_expression") parent-bol ,offset)
       ((parent-is "return_statement") parent-bol ,offset))))
  "Tree-sitter indent rules.")

(defvar php-ts-mode--keywords
  '("abstract" "as" "break" "case" "catch" "class" "const"
    "continue" "declare" "default" "do" "echo" "else"
    "elseif" "enddeclare" "endforeach" "endif" "endswitch"
    "endwhile" "enum" "extends" "final" "finally" "for" "foreach"
    "fn" "function" "global" "if" "implements" "include_once"
    "include" "insteadof" "interface" "namespace" "new"
    "private" "protected" "public" "readonly" "require_once" "require"
    "return" "static" "switch" "throw" "trait" "try" "use"
    "while" "yield")
  "PHP keywords for tree-sitter font-locking.")

(defvar php-ts-mode--operators
  '("!=" "!==" "%" "%=" "&" "&&" "&=" "*" "**" "*="
     "+" "++" "+=" "," "-" "-" "--" "-=" "->" "."
     ".=" "/" "/=" ":" "::" "<" "<<" "<<=" "<=" "<=>"
     "<>" "=" "==" "===" "=>" ">" ">=" ">>" ">>=" "?"
     "??" "??=" "?->" "@" "\\" "^" "^=" "|" "|=" "||")
  "PHP operators for tree-sitter font-locking.")

(defconst php-ts-mode--magical-constants
  '("__CLASS__" "__DIR__" "__FILE__" "__FUNCTION__" "__LINE__"
    "__METHOD__" "__NAMESPACE__" "__TRAIT__")
  "Magical keyword that is expanded at compile time.

These are different from \"constants\" in strict terms.
see https://www.php.net/manual/language.constants.predefined.php")

(defvar php-ts-mode--font-lock-settings
  (treesit-font-lock-rules

   :language 'php
   :feature 'preprocessor
   `([(php_tag)
      ("?>")]
     @php-php-tag)

   :language 'php
   :feature 'constant
   `((const_declaration (const_element (name) @font-lock-type-face))
     ((name) @php-magical-constant
      (:match ,(rx-to-string `(: bos (or ,@php-ts-mode--magical-constants) eos))
              @php-magical-constant))
     ((name) @php-constant
      (:match ,(rx bos (? "_") (in "A-Z") (+ (in "0-9A-Z_")) eos)
              @php-constant)))

   :language 'php
   :feature 'type
   `([(primitive_type)
      (cast_type)
      (bottom_type)
      (named_type (name) @php-type)
      (named_type (qualified_name) @php-type)
      (namespace_use_clause)
      (namespace_name (name))
      (optional_type "?" @php-type)]
     @php-type
     (class_interface_clause (name) @php-class)
     (class_constant_access_expression
      (name) @php-keyword
      (:match ,(rx bos "class" eos)
              @php-keyword))
     (class_constant_access_expression
      (name) @php-constant
      (:match ,(rx bos (? "_") (in "A-Z") (+ (in "0-9A-Z_")) eos)
              @php-constant))
     (class_constant_access_expression
      (name) @php-class)
     (class_constant_access_expression
      (qualified_name
       (namespace_name_as_prefix) @php-class
       (name) @php-class))
     [(boolean)
      (null)]
     @php-constant
     [(integer)
      (float)]
     @font-lock-number-face)

   :language 'php
   :feature 'definition
   `((class_declaration
      name: (name) @php-class)
     (interface_declaration
      name: (name) @php-class)
     (enum_declaration
      name: (name) @php-class)
     (trait_declaration
      name: (name) @php-class)
     (enum_case
      name: (name) @php-class)
     (base_clause (name) @php-class)
     (use_declaration (name) @php-class))

   :language 'php
   :feature 'function
   `((array_creation_expression "array" @php-builtin)
     (list_literal "list" @php-builtin)
     (method_declaration
      name: (name) @php-function-name)
     (function_call_expression
      function: [(qualified_name (name)) (name)] @php-function-call)
     (scoped_call_expression
      scope: (name) @php-class)
     (scoped_call_expression
      name: (name) @php-static-method-call)
     (scoped_property_access_expression
      scope: (name) @php-class)
     (member_call_expression
      name: (name) @php-method-call)
     (object_creation_expression (name) @php-class)
     (attribute (name) @php-class)
     (attribute (qualified_name) @php-class)

     (function_definition
      name: (name) @php-function-name))

   :language 'php
   :feature 'variables
   `((relative_scope) @font-lock-builtin-face
     (property_element
      (variable_name) @php-property-name)

     ;; ((name) @constructor
     ;;  (:match ,(rx-to-string '(: bos (in "A-Z")))))
     (member_access_expression name: (name) @php-property-name)
     ;;(variable_name (name) @font-lock-variable-name-face)
     (variable_name (name) @php-variable-name)
     (variable_name "$" @php-variable-sigil))

   :language 'php
   :feature 'this
   :override t
   `((variable_name "$" @php-this-sigil (name) @php-this
		    (:match ,(rx bos "this" eos) @php-this)))

   :language 'php
   :feature 'comment
   `(((comment) @font-lock-doc-face
      (:match ,(rx bos "/**")
              @font-lock-doc-face))
     (comment) @font-lock-comment-face)

   :language 'php
   :feature 'string
   `([(string)
      (string_content)
      (encapsed_string)
      (heredoc)
      (heredoc_body)
      (nowdoc_body)]
     @php-string)

   :language 'php
   :feature 'operator
   `([,@php-ts-mode--operators] @php-operator
     (binary_expression operator: ["and" "or" "xor"] @php-operator))

   :language 'php
   :feature 'keyword
   `([,@php-ts-mode--keywords] @php-keyword
     (print_intrinsic "print" @php-keyword)
     (goto_statement "goto" @php-keyword)
     (yield_expression "from" @php-keyword))

   :language 'php
   :feature 'label
   `((goto_statement (name) @php-keyword)
     (named_label_statement (name) @php-keyword))

   :language 'php
   :feature 'delimiter
   '((["," ":" ";" "\\"]) @font-lock-delimiter-face
     (class_constant_access_expression "::" @font-lock-preprocessor-face)
     (attribute_group ["#[" "]"] @font-lock-preprocessor-face))

   :language 'php
   :feature 'bracket
   `((["(" ")" "[" "]" "{" "}"]) @font-lock-bracket-face))
  "Tree-sitter font-lock settings for `php-ts-mode'.")

(defun php-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (pcase (treesit-node-type node)
    ((or "class_declaration"
         "enum_declaration"
         "function_definition"
         "interface_declaration"
         "method_declaration"
         "namespace_definition"
         "trait_declaration")
     (treesit-node-text
      (treesit-node-child-by-field-name node "name")
      t))))

(unless (eval-when-compile (fboundp 'php-base-mode))
  (define-derived-mode php-base-mode prog-mode "PHP base"
    "Generic major mode for editing PHP script.

This mode is intended to be inherited by concrete major modes.
Currently there are `php-mode' and `php-ts-mode'."
    :group 'php
    nil))

;;;###autoload
(define-derived-mode php-ts-mode php-base-mode "PHP"
  "Major mode for editing PHP files, powered by tree-sitter."
  :group 'php
  :syntax-table php-ts-mode--syntax-table

  (unless (treesit-ready-p 'php)
    (error "Tree-sitter for PHP isn't available"))

  (treesit-parser-create 'php)

  ;; Comments.
  (c-ts-common-comment-setup)
  (setq-local comment-start-skip
              (eval-when-compile
                (rx (group (or (: "#" (not (any "[")))
                               (: "/" (+ "/"))
                               (: "/*")))
                    (* (syntax whitespace)))))

  ;; Indent.
  (setq-local c-ts-common-indent-type-regexp-alist
              (eval-when-compile
                `((block . ,(rx (or "class_body"
                                    "array_creation_expression"
                                    "constructor_body"
                                    "annotation_type_body"
                                    "interface_body"
                                    "lambda_expression"
                                    "enum_body"
                                    "switch_block"
                                    "record_declaration_body"
                                    "block")))
                  (close-bracket . "}")
                  (if . "if_statement")
                  (else . ("if_statement" . "alternative"))
                  (for . "for_statement")
                  (while . "while_statement")
                  (do . "do_statement"))))
  (setq-local c-ts-common-indent-offset 'php-ts-mode-indent-offset)
  (setq-local treesit-simple-indent-rules php-ts-mode--indent-rules)
  (setq-local electric-indent-chars
              (append "{}():;," electric-indent-chars))

  (setq-local treesit-defun-name-function #'php-ts-mode--defun-name)

  ;; Navigation
  (setq-local treesit-defun-type-regexp
              (regexp-opt '("class_declaration"
                            "enum_declaration"
                            "function_definition"
                            "interface_declaration"
                            "method_declaration"
                            "namespace_definition"
                            "trait_declaration")))

  ;; Font-lock.
  (setq-local treesit-font-lock-settings php-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
              '((comment definition preprocessor)
                (keyword string type)
                (function constant label)
                (bracket delimiter operator variables this)))

  ;; Imenu.
  (setq-local treesit-simple-imenu-settings
              '(("Namespace" "\\`namespace_definition\\'" nil nil)
                ("Enum" "\\`enum_declaration\\'" nil nil)
                ("Class" "\\`class_declaration\\'" nil nil)
                ("Interface" "\\`interface_declaration\\'" nil nil)
                ("Trait" "\\`trait_declaration\\'" nil nil)
                ("Method" "\\`method_declaration\\'" nil nil)))

  (treesit-major-mode-setup))

(when (treesit-ready-p 'php)
  (add-to-list 'auto-mode-alist '("\\.php[s345]?\\'" . php-ts-mode)))

;;;###autoload
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(php "https://github.com/tree-sitter/tree-sitter-php" "master" "php/src")))

(provide 'php-ts-mode)
;;; php-ts-mode.el ends here
