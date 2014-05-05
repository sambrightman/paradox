;;; paradox.el --- A modern Packages Menu. Colored, with package ratings, and customizable.

;; Copyright (C) 2014 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>
;; URL: http://github.com/Bruce-Connor/paradox
;; Version: 1.0
;; Keywords: package packages mode-line
;; Package-Requires: ((emacs "24.1") (tabulated-list "1.0") (package "1.0") (dash "2.6.0") (cl-lib "1.0") (json "1.3"))
;; Prefix: paradox 
;; Separator: -

;;; Commentary:
;; 
;; Paradox can be installed from Melpa with M-x `package-install' RET
;; paradox.  
;; It can also be installed manually in the usual way, just be mindful of
;; the dependencies.
;; 
;; To use it, simply call M-x `paradox-list-packages' (instead of the
;; regular `list-packages').  
;; This will give you most features out of the box. If you want to be
;; able to star packages as well, just configure the
;; `paradox-github-token' variable then call `paradox-list-packages'
;; again.
;; 
;; If you'd like to stop using Paradox, you may call `paradox-disable'
;; and go back to using the regular `list-packages'.
;; 
;; ## Current Features ##
;; 
;; ### Several Improvements ###
;; 
;; Paradox implements many small improvements to the package menu
;; itself. They all work out of the box and are completely customizable!  
;; *(Also, hit `h' to see all keys.)*
;; 
;; * Visit the package's homepage with `v' (or just use the provided buttons).
;; * Shortcuts for package filtering:
;;     * <f r> filters by regexp (`occur');
;;     * <f u> display only packages with upgrades;
;;     * <f k> filters by keyword (emacs 24.4 only).
;; * `hl-line-mode' enabled by default.
;; * Display useful information on the mode-line and cleanup a bunch of
;;   useless stuff.
;; * **Customization!** Just call M-x `paradox-customize' to see what you can
;;   do.
;;     * Customize column widths.
;;     * Customize faces (`paradox-star-face', `paradox-status-face-alist' and `paradox-archive-face').
;;     * Customize local variables.
;; 
;; ### Package Ratings ###
;; 
;; Paradox also integrates with
;; **GitHub Stars**, which works as **rough** package rating system.  
;; That is, Paradox package menu will:
;; 
;; 1. Display the number of GitHub Stars each package has (assuming it's
;;    in a github repo, of course);
;; 2. Possibly automatically star packages you install, and unstar
;;    packages you delete (you will be asked the first time whether you
;;    want this);
;; 3. Let you star and unstar packages by hitting the `s' key;
;; 4. Let you star all packages you have installed with M-x `paradox-star-all-installed-packages'.
;; 
;; Item **1.** will work out of the box, the other items obviously
;; require a github account (Paradox will help you generate a token the
;; first time you call `paradox-list-packages').
;;   
;; ## How Star Displaying Works ##
;; 
;; We generate a map of <Package> Name -> Repository< from>
;; [Melpa](https://github.com/milkypostman/melpa.git)'s `recipe'
;; directory, some repos may correspond to more than one package. 
;; This map is used count the stars a given package has.
;; _This doesn't mean you need Melpa to see the star counts, the numbers
;; will be displayed regardless of what archives you use._
;; 
;; Currently, packages that are not hosted on GitHub are listed with a
;; blank star count, which is clearly different from 0-star packages
;; (which are displayed with a 0, obviously).  
;; If you know of an alternative that could be used for these packages,
;; [open an issue](https://github.com/Bruce-Connor/paradox/issues/new)
;; here, I'd love to hear.

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 

;;; Change Log:
;; 1.0   - 2014/05/05 - New Feature! The l key displays a list of recent commits under a package.
;; 1.0   - 2014/05/04 - q key is smarter. It closes other generated windows.
;; 1.0   - 2014/05/04 - j and k describe the next and previous entries.
;; 0.11  - 2014/05/01 - Sorting commands and keys (under "S").
;; 0.10  - 2014/04/26 - New help menu!
;; 0.10  - 2014/04/25 - Display description on a separate line with paradox-lines-per-entry.
;; 0.10  - 2014/04/25 - Links to package homepages.
;; 0.9.2 - 2014/04/15 - Fix advice being enabled automatically.
;; 0.9.2 - 2014/04/15 - Ask the user before automatically starring.
;; 0.9.1 - 2014/04/14 - paradox-filter-upgrades is informative when there are no upgrades.
;; 0.9   - 2014/04/14 - First full feature release.
;; 0.5   - 2014/04/14 - Star all installed packages.
;; 0.5   - 2014/04/13 - (Un)Star packages with the "s" key!.
;; 0.2   - 2014/04/13 - Control the face used for each status with paradox-status-face-alist.
;; 0.2   - 2014/04/13 - New archive face.
;; 0.2   - 2014/04/13 - Define filtering keys (fk, fu, fr).
;; 0.2   - 2014/04/11 - Hide buffer-name with paradox-display-buffer-name.
;; 0.2   - 2014/04/08 - Even better mode-line.
;; 0.2   - 2014/04/08 - Intelligent width for the "archive" column.
;; 0.2   - 2014/04/08 - Customizable widths.
;; 0.2   - 2014/04/08 - Prettier trunctation.
;; 0.1   - 2014/04/03 - Created File.
;;; Code:

(require 'package)
(require 'cl-lib)
(require 'dash)
(defconst paradox-version "1.0" "Version of the paradox.el package.")
(defun paradox-bug-report ()
  "Opens github issues page in a web browser. Please send any bugs you find.
Please include your emacs and paradox versions."
  (interactive)
  (message "Your paradox-version is: %s, and your emacs version is: %s.\nPlease include this in your report!"
           paradox-version emacs-version)
  (browse-url "https://github.com/Bruce-Connor/paradox/issues/new"))
(defun paradox-customize ()
  "Open the customization menu in the `paradox' group."
  (interactive)
  (customize-group 'paradox t))
(defgroup paradox nil
  "Customization group for paradox."
  :prefix "paradox-"
  :group 'emacs
  :package-version '(paradox . "0.1"))
(defun paradox--compat-p ()
  "Non-nil if we need to enable pre-24.4 compatibility features."
  (version< emacs-version "24.3.50"))

(defcustom paradox-column-width-package  18
  "Width of the \"Package\" column."
  :type 'integer
  :group 'paradox
  :package-version '(paradox . "0.1"))

(defcustom paradox-column-width-version  9
  "Width of the \"Version\" column."
  :type 'integer
  :group 'paradox
  :package-version '(paradox . "0.1"))

(defcustom paradox-column-width-status  10
  "Width of the \"Status\" column."
  :type 'integer
  :group 'paradox
  :package-version '(paradox . "0.1"))

(defcustom paradox-column-width-star 4
  "Width of the \"Star\" column."
  :type 'integer
  :group 'paradox
  :package-version '(paradox . "0.1"))

(defvar paradox--column-name-star
  (if (char-displayable-p ?★) "★" "*"))

(defcustom paradox-github-token nil
  "Access token to use for github actions.
Currently, that means (un)starring repos.

To generate an access token:
  1. Visit the page https://github.com/settings/tokens/new and
     login to github (if asked).
  2. Give the token any name you want (Paradox, for instance).
  3. The only permission we need is \"public_repo\", so unmark
     all others.
  4. Click on \"Generate Token\", copy the generated token, and
     save it to this variable by writing
         (setq paradox-github-token TOKEN)
     somewhere in your configuration and evaluating it (or just
     restart emacs).

This is similar to how erc or jabber handle authentication in
emacs, but the following disclaimer always worth reminding.

DISCLAIMER:
When you save this variable, DON'T WRITE IT ANYWHERE PUBLIC. This
token grants (very) limited access to your account."
  :type 'string
  :group 'paradox
  :package-version '(paradox . "0.2"))

(defcustom paradox-automatically-star 'unconfigured
  "When you install new packages, should they be automatically starred? 
NOTE: This variable has no effect if `paradox-github-token' isn't set.

Paradox is capable of automatically starring packages when you
install them, and unstarring when you delete them. This only
applies to actual installation/deletion, i.e. Paradox doesn't
auto (un)star packages that were simply upgraded.

If this variable is nil, this behaviour is disabled. \\<paradox-menu-mode-map>

On the Package Menu, you can always manually star packages with \\[paradox-menu-mark-star-unstar]."
  :type '(choice (const :tag "Yes." t)
                 (const :tag "No." nil)
                 (const :tag "Ask later." unconfigured))
  :group 'paradox
  :package-version '(paradox . "0.2"))

(defface paradox-name-face
  '((t :inherit link))
  "Face used on the package's name."
  :group 'paradox)
(defface paradox-homepage-button-face
  '((t :underline t :inherit font-lock-comment-face))
  "Face used on the homepage button."
  :group 'paradox)
;; (defface paradox-version-face
;;   '((t :inherit default))
;;   "Face used on the version column."
;;   :group 'paradox)
(defface paradox-archive-face
  '((t :inherit paradox-comment-face))
  "Face used on the archive column."
  :group 'paradox)
(defface paradox-star-face
  '((t :inherit font-lock-string-face))
  "Face used on the star column, for packages you haven't starred."
  :group 'paradox)
(defface paradox-starred-face
  '((t :weight bold :inherit paradox-star-face))
  "Face used on the star column, for packages you have starred."
  :group 'paradox)
(defface paradox-description-face
  '((t :inherit default))
  "Face used on the description column.
If `paradox-lines-per-entry' > 1, the face
`paradox-description-face-multiline' is used instead."
  :group 'paradox)
(defface paradox-description-face-multiline
  '((t :inherit font-lock-doc-face))
  "Face used on the description column when `paradox-lines-per-entry' > 1.
If `paradox-lines-per-entry' = 1, the face
`paradox-description-face' is used instead."
  :group 'paradox)

(defface paradox-comment-face
  '((((background light)) :foreground "Grey30")
    (((background dark)) :foreground "Grey60"))
  "Face used on faded out stuff."
  :group 'paradox)
(defface paradox-highlight-face
  '((t :weight bold :inherit font-lock-variable-name-face))
  "Face used on highlighted stuff."
  :group 'paradox)

(defvar paradox--star-count nil)
(defvar paradox--package-repo-list nil)

(defvar paradox--star-count-url
  "https://raw.github.com/Bruce-Connor/paradox/data/data"
  "Address of the raw star-count file.")

(defvar paradox-menu-mode-map package-menu-mode-map)
(define-prefix-command 'paradox--filter-map)
(define-key paradox-menu-mode-map "q" #'paradox-quit-and-close)
(define-key paradox-menu-mode-map "p" #'paradox-previous-entry)
(define-key paradox-menu-mode-map "n" #'paradox-next-entry)
(define-key paradox-menu-mode-map "k" #'paradox-previous-describe)
(define-key paradox-menu-mode-map "j" #'paradox-next-describe)
(define-key paradox-menu-mode-map "f" #'paradox--filter-map)
(define-key paradox-menu-mode-map "s" #'paradox-menu-mark-star-unstar)
(define-key paradox-menu-mode-map "h" #'paradox-menu-quick-help)
(define-key paradox-menu-mode-map "v" #'paradox-menu-visit-homepage)
(define-key paradox-menu-mode-map "l" #'paradox-menu-view-commit-list)
(define-key paradox-menu-mode-map "\r" #'paradox-push-button)
(define-key paradox-menu-mode-map "F" 'package-menu-filter)
(define-key paradox--filter-map "k" #'package-menu-filter)
(define-key paradox--filter-map "f" #'package-menu-filter)
(define-key paradox--filter-map "r" #'occur)
(define-key paradox--filter-map "o" #'occur)
(define-key paradox--filter-map "u" #'paradox-filter-upgrades)

(defun paradox--define-sort (name &optional key)
  "Define function and key for sorting."  
  (let ((symb (intern (format "paradox-sort-by-%s" (downcase name))))
        (key (or key (substring name 0 1))))
    (eval
     `(progn
        (defun ,symb
            (invert)
          ,(format "Sort Package Menu by the %s column." name)
          (interactive "P")
          (when invert
            (setq tabulated-list-sort-key (cons ,name nil)))
          (tabulated-list--sort-by-column-name ,name))
        (define-key paradox-menu-mode-map ,(concat "S" (upcase key)) ',symb)
        (define-key paradox-menu-mode-map ,(concat "S" (downcase key)) ',symb)))))

(paradox--define-sort "Package")
(paradox--define-sort "Status")
(paradox--define-sort paradox--column-name-star "*")

(defun paradox-next-describe (n)
  "Describe the next package."
  (interactive "p")
  (paradox-next-entry n)
  (call-interactively 'package-menu-describe-package))

(defun paradox-previous-describe (n)
  "Describe the previous package."
  (interactive "p")
  (paradox-previous-entry n)
  (call-interactively 'package-menu-describe-package))

(defun paradox-push-button ()
  "Push button under point, or describe package."
  (interactive)
  (if (get-text-property (point) 'action)
      (call-interactively 'push-button)
    (call-interactively 'package-menu-describe-package)))

(defvar paradox--key-descriptors
  '(("next," "previous," "install," "delete," ("execute," . 1) "refresh," "help")
    ("star," "visit homepage")
    ("list commits")
    ("filter by" "+" "upgrades" "regexp" "keyword")
    ("Sort by" "+" "Package name" "Status" "*(star)")))

(defun paradox-menu-quick-help ()
  "Show short key binding help for `paradox-menu-mode'.
The full list of keys can be viewed with \\[describe-mode]."
  (interactive)
  (message (mapconcat 'paradox--prettify-key-descriptor
                      paradox--key-descriptors "\n")))

(defun paradox-quit-and-close (kill)
  "Bury this buffer and close the window."
  (interactive "P")
  (if paradox--current-filter
      (package-show-package-list)
    (let ((log (get-buffer-window paradox--commit-list-buffer)))
      (when (window-live-p log)
        (quit-window kill log))
      (quit-window kill))))

(defvar paradox--package-count
  '(("total" . 0) ("built-in" . 0)
    ("obsolete" . 0) ("deleted" . 0)
    ("available" . 0) ("new" . 0)
    ("held" . 0) ("disabled" . 0)
    ("installed" . 0) ("unsigned" . 0)))

(defmacro paradox--cas (string)
  `(cdr (assoc-string ,string paradox--package-count)))

;;;###autoload
(defun paradox--refresh-star-count ()
  "Download the star-count file and populate the respective variable."
  (interactive)
  (with-current-buffer 
      (url-retrieve-synchronously paradox--star-count-url)
    (when (search-forward "\n\n") 
      (setq paradox--star-count (read (current-buffer)))
      (setq paradox--package-repo-list (read (current-buffer))))
    (kill-buffer))
  (when (stringp paradox-github-token)
    (paradox--refresh-user-starred-list)))

(defcustom paradox-hide-buffer-identification t
  "If non-nil, no buffer-name will be displayed in the packages buffer."
  :type 'boolean
  :group 'paradox
  :package-version '(paradox . "0.5"))
(defvaralias 'paradox-hide-buffer-name 'paradox-hide-buffer-identification)

(defun paradox--build-buffer-id (st n)
  (list st (list :propertize (int-to-string n)
                 'face 'mode-line-buffer-id)))

;;;###autoload
(defun paradox-list-packages (no-fetch)
  "Improved version of `package-list-packages'.
Shows star count for packages, and extra information in the
mode-line."
  (interactive "P")
  (when (paradox--check-github-token)
    (paradox-enable)
    (unless no-fetch (paradox--refresh-star-count))
    (package-list-packages no-fetch)))

(defun paradox-enable ()
  "Enable paradox, overriding the default package-menu."
  (interactive)
  (ad-activate 'package-menu-execute)
  (if (paradox--compat-p)
      (progn
        (require 'paradox-compat)
        (paradox--override-definition 'package-menu--print-info 'paradox--print-info-compat))
    (paradox--override-definition 'package-menu--print-info 'paradox--print-info))
  (paradox--override-definition 'package-menu--generate 'paradox--generate-menu)
  (paradox--override-definition 'truncate-string-to-width 'paradox--truncate-string-to-width)
  (paradox--override-definition 'package-menu-mode 'paradox-menu-mode))

(defvar paradox--backups nil)

(defun paradox-disable ()
  "Disable paradox, and go back to regular package-menu."
  (interactive)
  (ad-deactivate 'package-menu-execute)
  (dolist (it paradox--backups)
    (message "Restoring %s to %s" (car it) (eval (cdr it)))
    (fset (car it) (eval (cdr it))))
  (setq paradox--backups nil))

(defun paradox--override-definition (sym newdef)
  "Temporarily override SYM's function definition with NEWDEF.
The original definition is saved to paradox--SYM-backup."
  (let ((backup-name (intern (format "paradox--%s-backup" sym)))
        (def (symbol-function sym)))
    (unless (assoc sym paradox--backups)
      (message "Overriding %s with %s" sym newdef)
      (eval (list 'defvar backup-name nil))
      (add-to-list 'paradox--backups (cons sym backup-name))
      (set backup-name def)
      (fset sym newdef))))

;;; Right now this is trivial, but we leave it as function so it's easy to improve.
(defun paradox--active-p ()
  (null (null paradox--backups)))

(defun paradox--truncate-string-to-width (&rest args)
  "Like `truncate-string-to-width', except default ellipsis is \"…\" on package buffer."
  (when (and (eq major-mode 'paradox-menu-mode)
             (eq t (nth 4 args)))
    (setf (nth 4 args) (if (char-displayable-p ?…) "…" "$")))
  (apply paradox--truncate-string-to-width-backup args))

(defvar paradox--upgradeable-packages nil)
(defvar paradox--upgradeable-packages-number nil)
(defvar paradox--upgradeable-packages-any? nil)

(defun paradox-refresh-upgradeable-packages ()
  "Refresh the list of upgradeable packages."
  (interactive)
  (setq paradox--upgradeable-packages (package-menu--find-upgrades))
  (setq paradox--upgradeable-packages-number
        (length paradox--upgradeable-packages))
  (setq paradox--upgradeable-packages-any?
        (> paradox--upgradeable-packages-number 0)))

(defcustom paradox-status-face-alist
  '(("built-in"  . font-lock-builtin-face)
    ("available" . default)
    ("new"       . bold)
    ("held"      . font-lock-constant-face)
    ("disabled"  . font-lock-warning-face)
    ("installed" . font-lock-comment-face)
    ("deleted"   . font-lock-comment-face)
    ("unsigned"  . font-lock-warning-face))
  "List of (\"STATUS\" . FACE) cons cells.
When displaying the package menu, FACE will be used to paint the
Version, Status, and Description columns of each package whose
status is STATUS. "
  :type '(repeat (cons string face))
  :group 'paradox
  :package-version '(paradox . "0.2"))

(defcustom paradox-homepage-button-string "h"
  "String used to for the link that takes you to a package's homepage."
  :type 'string
  :group 'paradox
  :package-version '(paradox . "0.10"))

(defcustom paradox-use-homepage-buttons t
  "If non-nil a button will be added after the name of each package.
This button takes you to the package's homepage."
  :type 'boolean
  :group 'paradox
  :package-version '(paradox . "0.10"))

(defvar desc-suffix nil)
(defvar desc-prefix nil)

(defcustom paradox-lines-per-entry 1
  "Number of lines used to display each entry in the Package Menu.
1 Gives you the regular package menu.
2 Displays the description on a separate line below the entry.
3+ Adds empty lines separating the entries."
  :type 'integer
  :group 'paradox
  :package-version '(paradox . "0.10"))

(defvar-local paradox--repo nil)

(defun paradox--print-info (pkg)
  "Return a package entry suitable for `tabulated-list-entries'.
PKG has the form (PKG-DESC . STATUS).
Return (PKG-DESC [STAR NAME VERSION STATUS DOC])."
  (let* ((pkg-desc (car pkg))
         (status  (cdr pkg))
         (face (or (cdr (assoc-string status paradox-status-face-alist))
                   'font-lock-warning-face))
         (url (paradox--package-homepage pkg-desc))
         (name (symbol-name (package-desc-name pkg-desc)))
         (name-length (length name))
         (button-length (length paradox-homepage-button-string)))
    (paradox--incf status)
    (list pkg-desc
          `[,(concat 
              (propertize name
                          'face 'paradox-name-face
                          'button t
                          'follow-link t
                          'help-echo (format "Package: %s" name)
                          'package-desc pkg-desc
                          'action 'package-menu-describe-package)
              (if (and paradox-use-homepage-buttons url
                       (< (+ name-length button-length) paradox-column-width-package))
                  (concat
                   (make-string (- paradox-column-width-package name-length button-length) ?\s)
                   (propertize paradox-homepage-button-string
                               'face 'paradox-homepage-button-face
                               'mouse-face 'custom-button-mouse
                               'help-echo (format "Visit %s" url)
                               'button t
                               'follow-link t
                               'action 'paradox-menu-visit-homepage))
                ""))
            ,(propertize (package-version-join
                          (package-desc-version pkg-desc))
                         'font-lock-face face)
            ,(propertize status 'font-lock-face face)
            ,@(if (cdr package-archives)
                  (list (propertize (or (package-desc-archive pkg-desc) "")
                                    'font-lock-face 'paradox-archive-face)))
            ,(paradox--package-star-count (package-desc-name pkg-desc))
            ,(propertize ;; (package-desc-summary pkg-desc)
                         (concat desc-prefix (package-desc-summary pkg-desc) desc-suffix) ;└╰
                         'font-lock-face
                         (if (> paradox-lines-per-entry 1)
                             'paradox-description-face-multiline
                           'paradox-description-face))])))

(defvar paradox--commit-list-buffer "*Package Commit List*")

(defun paradox-menu-view-commit-list (pkg)
  "Visit the commit list of package named PKG.
PKG is a symbol. Interactively it is the package under point."
  (interactive '(nil))
  (let ((repo (cdr (assoc (paradox--get-or-return-package pkg)
                          paradox--package-repo-list))))
    (if repo
        (with-selected-window 
            (display-buffer (get-buffer-create paradox--commit-list-buffer))
          (paradox-commit-list-mode)
          (setq paradox--repo repo)
          (paradox--commit-list-update-entires)
          (tabulated-list-print))
      (message "Package %s is not a GitHub repo." pkg))))

(defun paradox-menu-visit-homepage (pkg)
  "Visit the homepage of package named PKG.
PKG is a symbol. Interactively it is the package under point."
  (interactive '(nil))
  (let ((url (paradox--package-homepage
              (paradox--get-or-return-package pkg))))
    (if (stringp url)
        (browse-url url)
      (message "Package %s has no homepage."
               (propertize (symbol-name pkg)
                           'face 'font-lock-keyword-face)))))

(unless (paradox--compat-p)
  (defun paradox--package-homepage (pkg)
    "PKG can be the package-name symbol or a package-desc object."
    (let* ((object   (if (symbolp pkg) (cadr (assoc pkg package-archive-contents)) pkg))
           (name     (if (symbolp pkg) pkg (package-desc-name pkg)))
           (extras   (package-desc-extras object))
           (homepage (cdr (assoc :url extras))))
      (or homepage
          (and (setq extras (cdr (assoc name paradox--package-repo-list)))
               (format "https://github.com/%s" extras)))))
  (defun paradox--get-or-return-package (pkg)
    (if (or (markerp pkg) (null pkg))
        (if (derived-mode-p 'package-menu-mode)
            (package-desc-name (tabulated-list-get-id))
          (error "Not in Package Menu."))
      pkg)))

(defun paradox--incf (status)
  (cl-incf (paradox--cas status))
  (unless (string= status "obsolete")
    (cl-incf (paradox--cas "total"))))

(defun paradox--entry-star-count (entry)
  (paradox--package-star-count
   ;; The package symbol should be in the ID field, but that's not mandatory,
   (or (ignore-errors (elt (car entry) 1))
       ;; So we also try interning the package name.
       (intern (car (elt (cadr entry) 0))))))

(defvar paradox--user-starred-list nil)

(defun paradox--package-star-count (package)
  (let ((count (cdr (assoc package paradox--star-count)))
        (repo (cdr-safe (assoc package paradox--package-repo-list))))
    (propertize  
     (format "%s" (or count ""))
     'face
     (if (and repo (assoc-string repo paradox--user-starred-list))
         'paradox-starred-face
       'paradox-star-face))))

(defvar paradox--column-index-star nil)

(defun paradox--star-predicate (A B)
  (> (string-to-number (elt (cadr A) paradox--column-index-star))
     (string-to-number (elt (cadr B) paradox--column-index-star))))

(defvar paradox--current-filter nil)
(make-variable-buffer-local 'paradox--current-filter)

(defun paradox--generate-menu (remember-pos packages &optional keywords)
  "Populate the Package Menu, without hacking into the header-format.
If REMEMBER-POS is non-nil, keep point on the same entry.
PACKAGES should be t, which means to display all known packages,
or a list of package names (symbols) to display.

With KEYWORDS given, only packages with those keywords are
shown."
  (mapc (lambda (x) (setf (cdr x) 0)) paradox--package-count)
  (let ((desc-prefix (if (> paradox-lines-per-entry 1) " \n      " ""))
        (desc-suffix (make-string (max 0 (- paradox-lines-per-entry 2)) ?\n)))
    (paradox-menu--refresh packages keywords))
  (setq paradox--current-filter
        (if keywords (mapconcat 'identity keywords ",")
          nil))
  (let ((idx (paradox--column-index "Package")))
    (setcar (aref tabulated-list-format idx)
            (if keywords
                (concat "Package[" paradox--current-filter "]")
              "Package")))
  (tabulated-list-print remember-pos)
  (tabulated-list-init-header)
  (paradox--update-mode-line)
  (paradox-refresh-upgradeable-packages))

(if (paradox--compat-p)
    (require 'paradox-compat)
  (defalias 'paradox-menu--refresh 'package-menu--refresh))

(defun paradox--column-index (regexp)
  (cl-position (format "\\`%s\\'" (regexp-quote regexp)) tabulated-list-format
            :test (lambda (x y) (string-match x (or (car-safe y) "")))))

(defun paradox-previous-entry (&optional n)
  "Move to previous entry, which might not be the previous line."
  (interactive "p")
  (paradox-next-entry (- n))
  (forward-line 0)
  (forward-button 1))

(defun paradox-next-entry (&optional n)
  "Move to next entry, which might not be the next line."
  (interactive "p")
  (dotimes (it (abs n))
    (let ((d (cl-signum n)))
      (forward-line (if (> n 0) 1 0))
      (if (eobp) (forward-line -1))
      (forward-button d))))

(defun paradox-filter-upgrades ()
  "Show only upgradable packages."
  (interactive)
  (if (null paradox--upgradeable-packages)
      (message "No packages have upgrades.")
    (package-show-package-list
     (mapcar 'car paradox--upgradeable-packages))
    (setq paradox--current-filter "Upgrade")))

(define-derived-mode paradox-menu-mode tabulated-list-mode "Paradox Menu"
  "Major mode for browsing a list of packages.
Letters do not insert themselves; instead, they are commands.
\\<paradox-menu-mode-map>
\\{paradox-menu-mode-map}"
  (hl-line-mode 1)  
  (paradox--update-mode-line)
  (when (paradox--compat-p)
    (require 'paradox-compat)
    (setq tabulated-list-printer 'paradox--print-entry-compat))
  (setq tabulated-list-format
        `[("Package" ,paradox-column-width-package package-menu--name-predicate)
          ("Version" ,paradox-column-width-version nil)
          ("Status" ,paradox-column-width-status package-menu--status-predicate)
          ,@(paradox--archive-format)
          (,paradox--column-name-star ,paradox-column-width-star paradox--star-predicate :right-align t)
          ("Description" 0 nil)])
  (setq paradox--column-index-star 
        (paradox--column-index paradox--column-name-star))
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "Status" nil))
  ;; (add-hook 'tabulated-list-revert-hook 'package-menu--refresh nil t)
  (add-hook 'tabulated-list-revert-hook 'paradox-refresh-upgradeable-packages nil t)
  (add-hook 'tabulated-list-revert-hook 'paradox--refresh-star-count nil t)
  (add-hook 'tabulated-list-revert-hook 'paradox--update-mode-line nil t)
  (tabulated-list-init-header)
  ;; We need package-menu-mode to be our parent, otherwise some
  ;; commands throw errors. But we can't actually derive from it,
  ;; otherwise its initialization will screw up the header-format. So
  ;; we "patch" it like this.
  (put 'paradox-menu-mode 'derived-mode-parent 'package-menu-mode)
  (run-hooks 'package-menu-mode-hook))

(defun paradox--archive-format ()
  (when (and (cdr package-archives) 
             (null (paradox--compat-p)))
    (list (list "Archive" 
                (apply 'max (mapcar 'length (mapcar 'car package-archives)))
                'package-menu--archive-predicate))))

(add-hook 'paradox-menu-mode-hook 'paradox-refresh-upgradeable-packages)

(defcustom paradox-local-variables
  '(mode-line-mule-info
    mode-line-client mode-line-modified
    mode-line-remote mode-line-position
    column-number-mode size-indication-mode
    (mode-line-front-space . " "))
  "Variables which will take special values on the Packages buffer.
This is a list, where each element is either SYMBOL or (SYMBOL . VALUE).

Each SYMBOL (if it is bound) will be locally set to VALUE (or
nil) on the Packages buffer."
  :type '(repeat (choice symbol (cons symbol sexp)))
  :group 'paradox
  :package-version '(paradox . "0.1"))

(defcustom paradox-display-buffer-name nil
  "If nil, *Packages* buffer name won't be displayed in the mode-line."
  :type 'boolean
  :group 'paradox
  :package-version '(paradox . "0.2"))

(defun paradox--update-mode-line ()
  (mapc #'paradox--set-local-value paradox-local-variables)
  (setq mode-line-buffer-identification
        (list
         `(line-number-mode
           ("(" (:propertize "%4l" face mode-line-buffer-id) "/"
            ,(int-to-string (line-number-at-pos (point-max))) ")"))
         (list 'paradox-display-buffer-name
               (propertized-buffer-identification
                (format "%%%sb" (length (buffer-name)))))
         '(paradox--current-filter ("[" paradox--current-filter "]"))
         '(paradox--upgradeable-packages-any?
           (" " (:eval (paradox--build-buffer-id "Upgrade:" paradox--upgradeable-packages-number))))         
         '(package-menu--new-package-list
           (" " (:eval (paradox--build-buffer-id "New:" (paradox--cas "new")))))
         " " (paradox--build-buffer-id "Installed:" (+ (paradox--cas "installed") (paradox--cas "unsigned")))
         `(paradox--current-filter
           "" (" " ,(paradox--build-buffer-id "Total:" (length package-archive-contents)))))))

(defun paradox--set-local-value (x)
  (let ((sym (or (car-safe x) x)))
    (when (boundp sym)
      (set (make-local-variable sym) (cdr-safe x)))))

(defadvice package-menu-execute 
    (around paradox-around-package-menu-execute-advice ())
  "Star/Unstar packages which were installed/deleted during `package-menu-execute'."
  (when (and (stringp paradox-github-token)
             (eq paradox-automatically-star 'unconfigured))
    (customize-save-variable
     'paradox-automatically-star
     (y-or-n-p "When you install new packages would you like them to be automatically starred?\n(They will be unstarred when you delete them) ")))
  (if (and (stringp paradox-github-token) paradox-automatically-star)
      (let ((before (paradox--repo-alist)) after)
        ad-do-it
        (setq after (paradox--repo-alist))
        (mapc #'paradox--star-repo
              (-difference (-difference after before) paradox--user-starred-list))
        (mapc #'paradox--unstar-repo
              (-intersection (-difference before after) paradox--user-starred-list))
        (package-menu--generate t t))
    ad-do-it))

(defun paradox--repo-alist ()
  (cl-remove-duplicates
   (remove nil 
           (--map (cdr-safe (assoc (car it) paradox--package-repo-list)) 
                  package-alist))))


;;; Github api stuff
(defmacro paradox--enforce-github-token (&rest forms)
  "If a token is defined, perform FORMS, otherwise ignore forms ask for it be defined."
  `(if (stringp paradox-github-token)
       (progn ,@forms)
     (setq paradox-github-token nil)
     (paradox--check-github-token)))

(defun paradox-menu-mark-star-unstar (&optional n)
  "Mark a package for (un)starring and move to the next line."
  (interactive "p")
  (paradox--enforce-github-token
   (unless paradox--user-starred-list
     (paradox--refresh-user-starred-list))
   ;; Get package name
   (let ((pkg (intern (car (elt (tabulated-list-get-entry) 0))))
         will-delete repo)
     (unless pkg (error "Couldn't find package-name for this entry."))
     ;; get repo for this package
     (setq repo (cdr-safe (assoc pkg paradox--package-repo-list)))
     ;; (Un)Star repo
     (if (not repo)
         (message "This package is not a GitHub repo.")
       (setq will-delete (member repo paradox--user-starred-list))
       (paradox--star-repo repo will-delete)
       (cl-incf (cdr (assoc pkg paradox--star-count))
             (if will-delete -1 1))
       (tabulated-list-set-col paradox--column-name-star
                               (paradox--package-star-count pkg)))))
  (forward-line 1))

(defun paradox-star-all-installed-packages ()
  "Star all of your currently installed packages.
No questions asked."
  (interactive)
  (paradox--enforce-github-token
   (mapc (lambda (x) (paradox--star-package-safe (car-safe x))) package-alist)))

(defun paradox--star-package-safe (pkg &optional delete query)
  (let ((repo (cdr-safe (assoc pkg paradox--package-repo-list))))
    (when (and repo (not (assoc repo paradox--user-starred-list)))
      (paradox--star-repo repo delete query))))

(defun paradox--star-repo (repo &optional delete query)
  (when (or (not query)
            (y-or-n-p (format "Really %sstar %s? "
                              (if delete "un" "") repo)))  
    (paradox--github-action-star repo delete)
    (message "%starred %s." (if delete "Uns" "S") repo)
    (if delete
        (setq paradox--user-starred-list
              (remove repo paradox--user-starred-list))
      (add-to-list 'paradox--user-starred-list repo))))
(defun paradox--unstar-repo (repo &optional delete query)
  (paradox--star-repo repo (not delete) query))

(defun paradox--refresh-user-starred-list ()
  (setq paradox--user-starred-list
        (paradox--github-action
         "user/starred?per_page=100" nil
         'paradox--full-name-reader)))

(defun paradox--prettify-key-descriptor (desc)
  (if (listp desc)
      (if (listp (cdr desc))
          (mapconcat 'paradox--prettify-key-descriptor desc "   ")
        (let ((place (cdr desc))
              (out (car desc)))
          (setq out (propertize out 'face 'paradox-comment-face))
          (add-text-properties place (1+ place) '(face paradox-highlight-face) out)
          out))
    (paradox--prettify-key-descriptor (cons desc 0))))

(defun paradox--full-name-reader ()
  "Return all \"full_name\" properties in the buffer. Much faster than `json-read'."
  (let (out)
    (while (search-forward-regexp
            "^ *\"full_name\" *: *\"\\(.*\\)\", *$" nil t)
      (add-to-list 'out (match-string-no-properties 1)))
    (goto-char (point-max))
    out))

(defun paradox--github-action-star (repo &optional delete no-result)
  (paradox--github-action (concat "user/starred/" repo)
                          (if (stringp delete) delete (if delete "DELETE" "PUT"))
                          (null no-result)))

(defun paradox--github-action (action &optional method reader max-pages)
  "Contact the github api performing ACTION with METHOD.
Default METHOD is \"GET\".

Action can be anything such as \"user/starred?per_page=100\". If
it's not a full url, it will be prepended with
\"https://api.github.com/\".

The api action might not work if `paradox-github-token' isn't set.
This function also handles the pagination used in github results,
results of each page are appended.

Return value is always a list.
- If READER is nil, the result of the action is completely
  ignored (no pagination is performed on this case, making it
  much faster).
- Otherwise:
  - If the result was a 404, the function returns nil;
  - Otherwise, READER is called as a function with point right
    after the headers and should always return a list. As a
    special exception, if READER is t, it is equivalent to a
    function that returns (t)."
  ;; Make sure the token's configured.
  (unless (string-match "\\`https://" action)
    (setq action (concat "https://api.github.com/" action)))
  ;; Make the request
  (message "Contacting %s" action)
  (let ((pages (if (boundp 'pages) (1+ pages) 1)) next)
    (append
     (with-temp-buffer
       (save-excursion
         (shell-command
          (if (stringp paradox-github-token) 
              (format "curl -s -i -d \"\" -X %s -u %s:x-oauth-basic \"%s\" "
                      (or method "GET") paradox-github-token action)
            
            (format "curl -s -i -d \"\" -X %s \"%s\" "
                    (or method "GET") action)) t))
       (when reader
         (unless (search-forward "\nStatus: " nil t)
           (message "%s" (buffer-string))
           (error ""))
         ;; 204 means OK, but no content.
         (if (looking-at "204") '(t)
           ;; 404 is not found.
           (if (looking-at "404") nil
             ;; Anything else gets interpreted.
             (when (search-forward-regexp "^Link: .*<\\([^>]+\\)>; rel=\"next\"" nil t)
               (setq next (match-string-no-properties 1)))
             (search-forward-regexp "^?$")
             (skip-chars-forward "[:blank:]\n")
             (delete-region (point-min) (point))
             (unless (eobp) (if (eq reader t) t (funcall reader)))))))
     (when (and next (or (null max-pages) (< pages max-pages)))
       (paradox--github-action next method reader)))))

(defun paradox--check-github-token ()
  (if (stringp paradox-github-token)
      t
    (if paradox-github-token
        t
      (if (not (y-or-n-p "Would you like to set up GitHub integration?
This will allow you to star/unstar packages from the Package Menu. "))
          (customize-save-variable 'paradox-github-token t)
        (describe-variable 'paradox-github-token)
        (when (get-buffer "*Help*")
          (switch-to-buffer "*Help*")
          (delete-other-windows))
        (if (y-or-n-p "Follow the instructions on the `paradox-github-token' variable.
May I take you to the token generation page? ")
            (browse-url "https://github.com/settings/tokens/new"))
        (message "Once you're finished, simply call `paradox-list-packages' again.")
        nil))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Paradox Commit List Mode
(defvar paradox--repo-commit-feed-format
  "https://github.com/%s/commits/master.atom")

(defun paradox--commit-tabulated-list (repo)
  (require 'json)
  (let ((feed (paradox--github-action (format "repos/%s/commits?per_page=100" repo)
                                      "GET" 'json-read 1)))
    (apply 'append (mapcar 'paradox--commit-print-info feed))))

(defun paradox--commit-print-info (x)
  (let* ((commit (cdr (assoc 'commit x)))
         (date  (cdr (assoc 'date (cdr (assoc 'committer commit)))))
         (title (split-string (cdr (assoc 'message commit)) "[\n\r][ \t]*" t))
         (url   (cdr (assoc 'url commit)))
         (cc    (cdr (assoc 'comment_count commit))))
    (cons 
     (list (cons (car title) x)
           (vector
            (propertize (format-time-string "%x" (date-to-time date))
                        'button t
                        'follow-link t
                        'action 'paradox-commit-list-visit-commit
                        'face 'link)
            (concat (if (> cc 0)
                        (propertize (format "(%s comments) " cc)
                                    'face 'font-lock-function-name-face)
                      "")
                    (or (car-safe title) ""))))
     (when (cdr title)
       (mapcar (lambda (m) (list (cons m x)
                            (vector "" m))) (cdr title))))))

(defun paradox--commit-list-update-entires ()
  (setq tabulated-list-entries
        (paradox--commit-tabulated-list paradox--repo)))

(defun paradox-commit-list-visit-commit (&optional ignore)
  "Visit this commit on GitHub."
  (interactive)
  (when (derived-mode-p 'paradox-commit-list-mode)
    (browse-url
     (cdr (assoc 'html_url (tabulated-list-get-id))))))

(defun paradox-previous-commit (&optional n)
  "Move to previous commit, which might not be the previous line."
  (interactive "p")
  (paradox-next-commit (- n)))

(defun paradox-next-commit (&optional n)
  "Move to next commit, which might not be the next line."
  (interactive "p")
  (dotimes (it (abs n))
    (let ((d (cl-signum n)))
      (forward-line d)
      (while (looking-at "  +")
        (forward-line d)))))

(define-derived-mode paradox-commit-list-mode
  tabulated-list-mode "Paradox Commit List"
  "Major mode for browsing a list of commits.
Letters do not insert themselves; instead, they are commands.
\\<paradox-commit-list-mode-map>
\\{paradox-commit-list-mode-map}"
  (hl-line-mode 1)
  (setq tabulated-list-format
        `[("Date" ,(length (format-time-string "%x" (current-time))) nil)
          ("Message" 0 nil)])
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key nil)
  (add-hook 'tabulated-list-revert-hook 'paradox--commit-list-update-entires)
  (tabulated-list-init-header))

(define-key paradox-commit-list-mode-map "" #'paradox-commit-list-visit-commit)
(define-key paradox-commit-list-mode-map "p" #'paradox-previous-commit)
(define-key paradox-commit-list-mode-map "n" #'paradox-next-commit)

(provide 'paradox)
;;; paradox.el ends here.
