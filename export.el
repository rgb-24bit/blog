;;; export.el --- export org to html

;; Copyright (C) 2018 by rgb-24bit

;; Usage: emacs --srcipt export.el

;;; Code:

(require 'org)

(defvar file-list nil)

(defun get-export-file-list (&optional ALL)
  "Get a list of files to export."
  (if ALL (setq file-list (append (directory-files "./2017" t "\\.org$")
                              (directory-files "./2018" t "\\.org$")))

    ;; new or modified file
    (let ((status (shell-command-to-string "git status"))
          (pattern "\\b[0-9/-a-z.]+\\.org\\b") (start 0))
      (while (string-match-p pattern status start)
        (setq file-list
              (append file-list (list (substring status (string-match pattern status start)
                                                 (match-end 0)))))
        (setq start (match-end 0))))))

(defun export-html-by-file-name (file-name)
  "export file to html."
  (if (file-exists-p file-name)
      (progn
        (setq work-buffer (or (find-buffer-visiting file-name)
                              (find-file-noselect file-name)))
        (princ (format "Export %s...\n" file-name))
        (with-current-buffer work-buffer (org-html-export-to-html))
        (kill-buffer work-buffer))))

(defun export-readme-to-index ()
  "export README.org as index html."
  (export-html-by-file-name "README.org")
  (rename-file "README.html" "index.html" t))

(defun init-export-env ()
  (load-file "htmlize.el")
  (setq make-backup-files nil)
  (setq inhibit-message t))

(progn
  (init-export-env)
  (get-export-file-list)
  (while (setq file-name (car file-list))
    (export-html-by-file-name file-name)
    (setq file-list (cdr file-list)))
  (export-readme-to-index))
