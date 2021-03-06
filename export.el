;;; export.el --- export org to html

;; Copyright (C) 2018 by rgb-24bit

;; Usage: emacs --srcipt export.el [all]

;;; Code:

(require 'org)

(defvar file-list nil)
(defvar directory-list (directory-files default-directory t "[0-9]+"))

(defun get-export-file-list (&optional export-all)
  "Get a list of files to export."
  (if export-all
      (dolist (directory directory-list)
        (setq file-list (append file-list (directory-files directory t "\\.org$"))))

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

(defun read-file-text (file-name)
  "read file content as text."
  (with-temp-buffer
    (insert-file-contents-literally file-name)
    (decode-coding-region (point-min) (point-max) 'utf-8 t)))

;; Refrence https://coldnew.github.io/a1ed40e3/
(defadvice org-html-paragraph (before org-html-paragraph-advice
                                      (paragraph contents info) activate)
  "Join consecutive Chinese lines into a single long line without
unwanted space when exporting org-mode to html."
  (let* ((origin-contents (ad-get-arg 1))
         (fix-regexp "[[:multibyte:]]")
         (fixed-contents
          (replace-regexp-in-string
           (concat
            "\\(" fix-regexp "\\) *\n *\\(" fix-regexp "\\)") "\\1\\2" origin-contents)))
    (ad-set-arg 1 fixed-contents)))

(defun init-export-env ()
  ;; Dependency
  (load-file "htmlize.el")

  ;; No backup file
  (setq make-backup-files nil)

  ;; Do not output the message
  (setq inhibit-message t)

  ;; Export settings
  (setq org-export-default-language "zh-CN")
  (setq org-export-with-sub-superscripts nil)
  (setq org-export-with-broken-links t)
  (setq org-html-postamble t)
  (setq org-html-postamble (read-file-text "misc/post-body.html"))

  ;; HTML Specific export settings
  (setq org-html-doctype "html5")
  (setq org-html-htmlize-output-type 'css)
  (setq org-html-link-home "https://rgb-24bit.github.io")
  (setq org-html-link-up "https://rgb-24bit.github.io/blog/")
  (setq org-html-head (read-file-text "misc/post-head.html")))

(progn
  (init-export-env)
  (get-export-file-list (string= "all" (format "%s" (elt argv 0))))
  (while (setq file-name (car file-list))
    (export-html-by-file-name file-name)
    (setq file-list (cdr file-list))))
