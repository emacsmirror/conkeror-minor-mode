;;; conkeror-minor-mode.el --- Mode for editing conkeror javascript files.

;; Copyright (C) 2013 Artur Malabarba <bruce.connor.am@gmail.com>

;; Author: Artur Malabarba <bruce.connor.am@gmail.com>>
;; URL: http://github.com/BruceConnor/conkeror-minor-mode
;; Version: 1.3
;; Keywords: programming tools
;; Prefix: conkeror
;; Separator: -

;;; Commentary:
;;
;; conkeror-minor-mode
;; ===================
;; 
;; Mode for editing conkeror javascript files.
;; 
;; Currently, this only defines a function (for sending current
;; javascript statement to be evaluated by conkeror) and binds it to a
;; key. This function is `eval-in-conkeror' bound to **C-c C-c**.
;; 
;; Installation:
;; =============
;; 
;; If you install manually, require it like this,
;; 
;;     (require 'conkeror-minor-mode)
;;     
;; then follow activation instructions below.
;; 
;; If you install from melpa just follow the activation instructions.
;; 
;; Activation
;; ==========
;; 
;; It is up to you to define when `conkeror-minor-mode' should be
;; activated. If you want it on every javascript file, just do
;; 
;;     (add-hook 'js-mode-hook 'conkeror-minor-mode)
;; 
;; If you want it only on some files, do something like:
;; 
;;     (add-hook 'js-mode-hook (lambda ()
;;                               (when (string= ".conkerorrc" (buffer-file-name))
;;                                 (conkeror-minor-mode 1))))
;; 
;;

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
;; 1.3 - 20131025 - Font-locking
;; 1.0 - 20131025 - Created File.
;;; Code:

(defconst conkeror-minor-mode-version "1.3" "Version of the conkeror-minor-mode.el package.")
(defconst conkeror-minor-mode-version-int 2 "Version of the conkeror-minor-mode.el package, as an integer.")
(defun conkeror-bug-report ()
  "Opens github issues page in a web browser. Please send me any bugs you find, and please inclue your emacs and conkeror versions."
  (interactive)
  (message "Your conkeror-version is: %s, and your emacs version is: %s.
Please include this in your report!"
           conkeror-version emacs-version)
  (browse-url "https://github.com/BruceConnor/conkeror-minor-mode/issues/new"))
(defun conkeror-customize ()
  "Open the customization menu in the `conkeror-minor-mode' group."
  (interactive)
  (customize-group 'conkeror-minor-mode t))

(defcustom conkeror-file-path nil
  "The path to a script that runs conkeror, or to the \"application.ini\" file.

If this is nil we'll try to find an executable called
\"conkeror\" or \"conkeror.sh\" in your path."
  :type 'string
  :group 'conkeror-minor-mode)

(defun eval-in-conkeror ()
  "Send current javacript statement to conqueror.

This command determines the current javascript statement under
point and evaluates it in conkeror. The point of this is NOT to
gather the result (there is no return value), but to customize
conkeror directly from emacs by setting variables, defining
functions, etc.

If mark is active, send the current region instead of current
statement."
  (interactive)
  (message "Result was:\n%s"
           (let ((comm 
                  (concat
                   (conkeror--command)
                   " -q -batch -e "
                   (conkeror--wrap-in ?' (js--current-statement)))))
             (message "Running:\n%s" comm)
             (shell-command-to-string comm))))

(defun conkeror--wrap-in (quote text)
  "Wrap TEXT in QUOTE and escape instances of QUOTE inside it.

Escapes by wrapping such instances in themselves and adding a
backslash. This may seems excessive, but it's intended for use
with single quotes in linux command shells."
  (let ((st (if (stringp quote) quote (char-to-string quote))))    
    (concat st
            (replace-regexp-in-string
             (regexp-quote st)
             (concat st "\\\\\\&" st)
             text t)
            st)))

(defun conkeror--command ()
  "Generate the string for the conkeror command."
  (if (stringp conkeror-file-path)
      (if (file-name-absolute-p conkeror-file-path)      
          (if (string-match "\.ini\\'" conkeror-file-path)
              (concat (executable-find "xulrunner")
                      " " (expand-file-name conkeror-file-path))
            (expand-file-name conkeror-file-path))
        (error "%S must be absolute." 'conkeror-file-path))
    (or
     (executable-find "conkeror")
     (executable-find "conkeror.sh")
     (error "Couldn't find a conkeror executable! Please set %S." 'conkeror-file-path))))

(defun js--current-statement ()
  (if (region-active-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (let ((l (point-min))
          initial-point r)
      (save-excursion
        (skip-chars-backward "[:blank:]\n")
        (setq initial-point (point))
        (goto-char (point-min))
        (while (and (skip-chars-forward "[:blank:]\n")
                    (null r)
                    (null (eobp)))
          (when (looking-at ";")
            (forward-char 1)
            (if (>= (point) initial-point)
                (setq r (point))
              (forward-sexp 1) ;(Skip over comments and whitespace)
              (forward-sexp -1)
              (setq l (point))))
          (forward-sexp 1)))
      (buffer-substring-no-properties l r))))

(defconst conkeror--font-lock-keywords
  '(;; keywords
    ("\\_<\\(\\$\\(?:a\\(?:ction\\|l\\(?:ign\\|low_www\\|ternative\\)\\|nonymous\\|rgument\\|uto\\(?:_complete\\(?:_\\(?:delay\\|initial\\)\\)?\\)?\\)\\|b\\(?:inding\\(?:_list\\|s\\)?\\|rowser_object\\|uffers?\\)\\|c\\(?:harset\\|lass\\|o\\(?:m\\(?:mand\\(?:_list\\)?\\|plet\\(?:er\\|ions\\)\\)\\|nstructor\\)\\|rop\\|wd\\)\\|d\\(?:e\\(?:fault\\(?:_completion\\)?\\|scription\\)\\|isplay_name\\|o\\(?:c\\|mains?\\)\\)\\|f\\(?:allthrough\\|ds\\|lex\\)\\|get_\\(?:description\\|string\\)\\|h\\(?:e\\(?:aders\\|lp\\)\\|i\\(?:nt\\(?:_xpath_expression\\)?\\|story\\)\\)\\|in\\(?:dex_file\\|fo\\|itial_value\\)\\|key\\(?:_sequence\\|map\\)\\|load\\|m\\(?:atch_required\\|od\\(?:ality\\|e\\)\\|ultiple\\)\\|name\\(?:space\\)?\\|o\\(?:bject\\|p\\(?:ener\\|ml_file\\|tions\\)\\|ther_bindings\\|verride_mime_type\\)\\|p\\(?:a\\(?:rent\\|ssword\\|th\\)\\|erms\\|osition\\|r\\(?:e\\(?:fix\\|pare_download\\)\\|ompt\\)\\)\\|re\\(?:gexps\\|peat\\)\\|s\\(?:elect\\|hell_command\\(?:_cwd\\)?\\)\\|t\\(?:e\\(?:mp_file\\|st\\)\\|lds\\)\\|u\\(?:rl\\(?:\\(?:_prefixe\\)?s\\)\\|se\\(?:_\\(?:bookmarks\\|cache\\|history\\|webjumps\\)\\|r\\)\\)\\|va\\(?:lidator\\|riable\\)\\|wrap_column\\)\\)\\_>"
     1 font-lock-constant-face)
    ;; Major functions
    ("\\_<\\(\\(?:interactiv\\|requir\\)e\\)\\_>\\s-*("
     1 font-lock-keyword-face)
    ;; common functions
    ("\\(a\\(?:dd_hook\\|lternates\\)\\|build_url_regexp\\|call_on_focused_field\\|define_\\(?:browser_object_class\\|key\\(?:map\\(?:s_page_mode\\)?\\)?\\|webjump\\)\\|exec\\|focus_next\\|mod\\(?:e_line_\\(?:adder\\|mode\\)\\|ify_region\\)\\|p\\(?:age_mode_activate\\|op\\|ush\\)\\|re\\(?:ad_from_clipboard\\|gister_user_stylesheet\\|move_hook\\)\\|s\\(?:e\\(?:ssion_pref\\|t_protocol_handler\\)\\|witch_to_buffer\\)\\|test\\)\\s-*("
     1 font-lock-function-name-face)
    ;; keymaps
    ("\\_<\\(\\(?:c\\(?:aret\\|ontent_buffer_\\(?:anchor\\|button\\|checkbox\\|embed\\|form\\|normal\\|richedit\\|select\\|text\\(?:area\\)?\\)\\)\\|d\\(?:ef\\(?:ault_\\(?:base\\|global\\|help\\)\\|ine\\)\\|ownload_buffer\\|uckduckgo\\(?:_\\(?:anchor\\|select\\)\\)?\\)\\|f\\(?:acebook\\|eedly\\|ormfill\\)\\|g\\(?:ithub\\|lobal_overlay\\|ma\\(?:il\\|ne\\)\\|oogle_\\(?:calendar\\|gqueues\\|maps\\|reader\\|search_results\\|voice\\)\\|rooveshark\\)\\|h\\(?:elp_buffer\\|int\\(?:_quote_next\\)?\\)\\|isearch\\|key_binding_reader\\|list_by\\|minibuffer\\(?:_\\(?:base\\|message\\|space_completion\\)\\)?\\|new\\(?:sblur\\)?\\|over\\(?:lay\\|ride\\)\\|quote\\(?:_next\\)?\\|re\\(?:ad_buffer\\|ddit\\)\\|s\\(?:equence_\\(?:abort\\|help\\)\\|ingle_character_options_minibuffer\\|pecial_buffer\\|tackexchange\\)\\|t\\(?:arget\\|ext\\|witter\\)\\|universal_argument\\|wikipedia\\|youtube_player\\)_keymap\\)\\_>"
     1 font-lock-variable-name-face)
    ;; mods
    ("\\_<\\(\\(?:d\\(?:ailymotion\\|uckduckgo\\)\\|f\\(?:acebook\\|eedly\\)\\|g\\(?:ithub\\|ma\\(?:il\\|ne\\)\\|oogle_\\(?:calendar\\|gqueues\\|images\\|maps\\|reader\\|search_results\\|v\\(?:ideo\\|oice\\)\\)\\|rooveshark\\)\\|key_kill\\|newsblur\\|reddit\\|s\\(?:mbc\\|tackexchange\\)\\|twitter\\|wikipedia\\|xkcd\\|youtube\\(?:_player\\)?\\)_mode\\)\\_>"
     1 font-lock-variable-name-face)
    ;; user variables
    ("\\_<\\(a\\(?:ctive_\\(?:\\(?:img_\\)?hint_background_color\\)\\|llow_browser_window_close\\|uto_mode_list\\)\\|b\\(?:lock_content_focus_change_duration\\|rowser_\\(?:automatic_form_focus_window_duration\\|default_open_target\\|form_field_xpath_expression\\|relationship_patterns\\)\\|ury_buffer_position\\)\\|c\\(?:an_kill_last_buffer\\|l\\(?:icks_in_new_buffer_\\(?:button\\|target\\)\\|ock_time_format\\)\\|ontent_handlers\\|wd\\)\\|d\\(?:aemon_quit_exits\\|e\\(?:fault_minibuffer_auto_complete_delay\\|lete_temporary_files_for_command\\)\\|ownload_\\(?:buffer_\\(?:automatic_open_target\\|min_update_interval\\)\\|temporary_file_open_buffer_delay\\)\\)\\|e\\(?:dit\\(?:_field_in_external_editor_extension\\|or_shell_command\\)\\|xternal_\\(?:\\(?:content_handler\\|editor_extension_override\\)s\\)\\|ye_guide_\\(?:context_size\\|highlight_new\\|interval\\)\\)\\|f\\(?:avicon_image_max_size\\|orced_charset_list\\)\\|generate_filename_safely_fn\\|h\\(?:int\\(?:_\\(?:background_color\\|digits\\)\\|s_a\\(?:\\(?:mbiguous_a\\)?uto_exit_delay\\)\\)\\|omepage\\)\\|i\\(?:mg_hint_background_color\\|ndex_\\(?:webjumps_directory\\|xpath_webjump_tidy_command\\)\\|search_keep_selection\\)\\|k\\(?:ey\\(?:_bindings_ignore_capslock\\|board_key_sequence_help_timeout\\)\\|ill_whole_line\\)\\|load_paths\\|m\\(?:edia_scrape\\(?:_default_regexp\\|rs\\)\\|i\\(?:me_type_external_handlers\\|nibuffer_\\(?:auto_complete_\\(?:default\\|preferences\\)\\|completion_rows\\|history_max_items\\|input_mode_show_message_timeout\\|read_url_select_initial\\)\\)\\)\\|new_buffer_\\(?:\\(?:with_opener_\\)?position\\)\\|opensearch_load_paths\\|r\\(?:ead_\\(?:buffer_show_icons\\|url_handler_list\\)\\|un_external_editor_function\\)\\|title_format_fn\\|url_\\(?:completion_\\(?:sort_order\\|use_\\(?:bookmarks\\|history\\|webjumps\\)\\)\\|remoting_fn\\)\\|view_source_\\(?:function\\|use_external_editor\\)\\|w\\(?:ebjump_partial_match\\|indow_extra_argument_max_delay\\)\\|xkcd_add_title\\)\\_>"
     1 font-lock-variable-name-face)))

;;;###autoload
(define-minor-mode conkeror-minor-mode nil nil " Conk"
  '(("" . eval-in-conkeror))
  :group 'conkeror-minor-mode
  (if conkeror-minor-mode  ;(regexp-opt '())
      (font-lock-add-keywords
       nil
       conkeror--font-lock-keywords)))


(provide 'conkeror-minor-mode)
;;; conkeror-minor-mode.el ends here.














