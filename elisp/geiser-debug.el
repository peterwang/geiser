;; geiser-debug.el -- displaying debug information

;; Copyright (C) 2009 Jose Antonio Ortega Ruiz

;; Author: Jose Antonio Ortega Ruiz <jao@gnu.org>
;; Start date: Mon Feb 23, 2009 22:34

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Comentary:

;; Buffer and associated mode for displaying results of evaluations
;; and compilations.

;;; Code:

(require 'geiser-eval)
(require 'geiser-popup)
(require 'geiser-base)


;;; Debug buffer mode:

(defvar geiser-debug-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (set-keymap-parent map button-buffer-map)
    map))

(defun geiser-debug-mode ()
  "A major mode for displaying Scheme compilation and evaluation results.
\\{geiser-debug-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (buffer-disable-undo)
  (use-local-map geiser-debug-mode-map)
  (set-syntax-table scheme-mode-syntax-table)
  (setq mode-name "Geiser DBG")
  (setq major-mode 'geiser-debug-mode)
  (setq buffer-read-only t))


;;; Buffer for displaying evaluation results:

(geiser-popup--define debug "*Geiser dbg*" geiser-debug-mode)


;;; Displaying retorts

(defun geiser-debug--display-retort (what ret)
  (let* ((err (geiser-eval--retort-error ret))
         (output (geiser-eval--retort-output ret)))
    (geiser-debug--with-buffer
      (erase-buffer)
      (insert what)
      (newline 2)
      (when err (insert (geiser-eval--error-str err) "\n\n"))
      (when output (insert output "\n\n"))
      (goto-char (point-min)))
    (when err (geiser-debug--pop-to-buffer))))

(defsubst geiser-debug--wrap-region (str)
  (format "(begin %s)" str))

(defun geiser-debug--unwrap (str)
  (if (string-match "(begin[ \t\n\v\r]+\\(.+\\)*)" str)
      (match-string 1 str)
    str))

(defun geiser-debug--send-region (compile start end and-go wrap)
  (let* ((str (buffer-substring-no-properties start end))
         (wrapped (if wrap (geiser-debug--wrap-region str) str))
         (code `(,(if compile :comp :eval) (:scm ,wrapped)))
         (ret (geiser-eval--send/wait code))
         (err (geiser-eval--retort-error ret)))
    (when and-go (funcall and-go))
    (when (not err) (message (format "=> %s" (geiser-eval--retort-result ret))))
    (geiser-debug--display-retort str ret)))

(defun geiser-debug--expand-region (start end all wrap)
  (let* ((str (buffer-substring-no-properties start end))
         (wrapped (if wrap (geiser-debug--wrap-region str) str))
         (code `(:eval ((:ge macroexpand) (quote (:scm ,wrapped))
                        ,(if all :t :f))))
         (ret (geiser-eval--send/wait code))
         (err (geiser-eval--retort-error ret))
         (result (geiser-eval--retort-result ret)))
    (if err
        (geiser-debug--display-retort str ret)
      (geiser-debug--with-buffer
        (erase-buffer)
        (insert (format "%s" (if wrap (geiser-debug--unwrap result) result)))
        (goto-char (point-min)))
      (geiser-debug--pop-to-buffer))))


(provide 'geiser-debug)
;;; geiser-debug.el ends here
