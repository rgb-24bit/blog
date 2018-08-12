;;; export.el --- export org to html

;; Copyright (C) 2018 by rgb-24bit

;; Usage: emacs --srcipt export.el [all]

;;; Code:

(require 'org)

(defvar file-list nil)
(defvar directory-list '("./2017" "./2018"))

(defun get-export-file-list (&optional ALL)
  "Get a list of files to export."
  (if ALL
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

(defun export-readme-to-index ()
  "export README.org as index html."
  (export-html-by-file-name "README.org")
  (rename-file "README.html" "index.html" t))

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
  (setq org-html-postamble t)
  (setq org-html-postamble-format
        '(("en"
           "版权声明:自由转载-非商用-非衍生-保持署名(<a href=\"http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh\">创意共享3.0许可证</a>)
           <div id=\"disqus_thread\"></div>
           <script type=\"text/javascript\">
             var disqus_shortname = 'rgb-24bit';
             (function() {
               var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
               dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
               (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
             })();
           </script>")))

  ;; HTML Specific export settings
  (setq org-html-doctype "html5")
  (setq org-html-link-home "https://rgb-24bit.github.io")
  (setq org-html-link-up "https://rgb-24bit.github.io/blog/")
  (setq org-html-head "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://rgb-24bit.github.io/org-html-theme-list/org-note/style/main.css\"/>"))

(progn
  (init-export-env)
  (get-export-file-list (string= "all" (format "%s" (elt argv 0))))
  (while (setq file-name (car file-list))
    (export-html-by-file-name file-name)
    (setq file-list (cdr file-list)))
  (export-readme-to-index))
