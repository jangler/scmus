;;
;; Copyright 2014-2018 Drew Thoreson
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, see <http://www.gnu.org/licenses/>.
;;

(require-extension matchable)

(import drewt.ncurses
        scmus.base
        scmus.client
        scmus.command
        scmus.command-line
        scmus.config
        scmus.ueval
        scmus.event
        scmus.format
        scmus.keys
        scmus.option
        scmus.status
        scmus.track
        scmus.tui
        scmus.view
        scmus.widgets)

;; Export an identifier unchanged (for SRFIs).
(define-syntax export-identifier!
  (syntax-rules ()
    ((export-identifier identifier)
      (user-export! (quote identifier) identifier))))

(define-syntax export/user
  (syntax-rules ()
    ((export/user name doc)
      (user-value-set! (quote name) name doc))))

(define-syntax define/user
  (syntax-rules ()
    ((define/user (name . args) doc first . rest)
      (user-value-set! (quote name) (lambda args first . rest) doc))
    ((define/user name doc value)
      (user-value-set! (quote name) value doc))))

(define-syntax define+user
  (syntax-rules ()
    ((define+user (name . args) doc first . rest)
      (begin (define (name . args) first . rest)
             (export/user name doc)))))

;; More succinct syntax for defining thunks, + ensuring that they return void.
(define-syntax thunk
  (syntax-rules ()
    ((thunk body ...)
       (lambda () body ... (void)))))

;; Syntax for creating a function wrapper which discards the return value.
(define-syntax return-void
  (syntax-rules ()
    ((return-void fun)
       (lambda args (apply fun args) (void)))))

(define-syntax user-synonym
  (syntax-rules ()
    ((user-synonym new old)
      (user-export! (quote new) (*user-value-ref (quote old))))))

(: *user-events* (list-of symbol))
(define *user-events*
  '(track-changed))

;; macros {{{

(define (user-syntax-error name arg-list)
  (raise (make-composite-condition
           (make-property-condition 'exn
                                    'message (format "Syntax error: in expansion of ~a" name)
                                    'arguments (cons name arg-list)
                                    'location name)
           (make-property-condition 'syntax))))

(user-macro-set! (string->symbol "\u03bb")
  (lambda (args) (cons 'lambda args)))

(user-macro-set! 'define-command
  (match-lambda
    ((((? symbol? name) . args) first . rest)
      `(register-command! (quote ,name)
         (lambda ,args ,first . ,rest)
         #t))
    (expr (user-syntax-error 'define-command expr))))

;; macros }}}
;; procedures {{{

(define/user (bind keys context expr #!optional (force #f))
  "Bind a key sequence to a Scheme expression"
  (let ((key-list (if (list? keys) keys (string-tokenize keys)))
        (expr (if (string? expr) `(*command ,expr) expr)))
    (if (binding-keys-valid? key-list)
      (begin
        (when force
          (unbind! key-list context))
        (make-binding! key-list context expr))
      #f)))
(user-synonym bind! bind)

(define/user can-set-color?
  "Returns #t if SET-COLOR can be used, otherwise #f"
  can-set-color?)

(define/user clear-queue
  "Clear the queue"
  (return-void scmus-clear!))
(user-synonym clear-queue! clear-queue)

(define/user (colorscheme str)
  "Set the color scheme"
  (cond
    ((file-exists? (format "~a/colors/~a.scm" *user-config-dir* str))
      => user-load)
    ((file-exists? (format "~a/colors/~a.scm" *scmus-dir* str))
      => user-load)))
(user-synonym colorscheme! colorscheme)

(define/user (command name . args)
  "Execute a command"
  (eval-command (map (lambda (x)
                       (with-input-from-string (if (string? x) x (format "~a" x))
                         read-command/implicit-quote))
                     (cons name args))))

(define/user (*command str)
  "Execute a command"
  (run-command str))

(define/user connect
  "Connect to an MPD server"
  ; XXX: connect! not defined yet
  (lambda args (apply connect! args)))
(user-synonym connect! connect)

(define/user consume?
  "Check if MPD is in consume mode"
  scmus-consume?)

(define/user consume-set
  "Set consume mode on or off"
  (return-void scmus-consume-set!))
(user-synonym consume-set! consume-set)

(define/user current-bitrate
  "Get the current bitrate of the current track"
  scmus-bitrate)

(define/user current-elapsed
  "Get the elapsed time of the current track"
  scmus-elapsed)

(define/user (current-track)
  "Get the current track"
  (current-track))

(define/user current-volume
  "Get the current volume"
  scmus-volume)

(let ((unbound-object (cons 0 0)))
  (define/user (describe symbol)
    "Describe a symbol"
    (command-line-print-info!
      (if (not (symbol? symbol))
        (format "~s" symbol)
        (let ((info (user-doc-ref symbol))
              (bind (*user-value-ref symbol unbound-object)))
          (cond
            ((eq? bind unbound-object)
              (format "~a: unbound" symbol))
            ((not info)
               (format "~a: ~s" symbol bind))
            (else
               (format "~a: ~a" symbol info))))))))

(define/user disconnect
  "Disconnect from the MPD server"
  (return-void scmus-disconnect!))
(user-synonym disconnect! disconnect)

(define/user (echo arg)
  "Echo a value on the command line"
  (define (clean-text text)
    (string-delete (lambda (x)
                     (case x
                       ((#\newline #\linefeed) #t)
                       (else #f)))
                   text))
  (command-line-print-info! (clean-text (format #f "~a" arg)))
  arg)
(user-synonym echo! echo)

(define eval-mode
  (make-command-line-mode "$"
    (lambda (s)
      (when s
        (let ((r (user-eval-string s)))
          (if (and (not (condition? r))
                   (not (eqv? r (void)))
                   (get-option 'eval-mode-print))
            (command-line-print-info! (format "~s" r))))))))

(define command-mode
  (make-command-line-mode ":"
    (lambda (s)
      (when s (run-command s)))
    engine: (make-completion-engine
              char-set:graphic
              command-completion)))

(define current-search-query (make-parameter #f))
(define searching-backward? (make-parameter #f))

(define search-mode
  (make-command-line-mode "/"
    (lambda (s)
      (when s
        (current-search-query s)
        (searching-backward? #f)
        (widget-search (widget-focus view-widget) s #f)))))

(define search-backward-mode
  (make-command-line-mode "?"
    (lambda (s)
      (when s
        (current-search-query s)
        (searching-backward? #t)
        (widget-search (widget-focus view-widget) s #t)))))

(define+user (enter-eval-mode #!optional (text "") (cursor-pos 0))
  "Set the input mode to eval-mode"
  (command-line-enter-mode eval-mode text cursor-pos))

(define/user (enter-command-mode #!optional (text "") (cursor-pos 0))
  "Set the input mode to command-mode"
  (command-line-enter-mode command-mode text cursor-pos))

(define/user (enter-search-mode #!optional (text "") (cursor-pos 0))
  "Set the input mode to search-mode"
  (command-line-enter-mode search-mode text cursor-pos))

(define/user (enter-search-mode/backward #!optional (text "") (cursor-pos 0))
  "Set the input mode to search-backward-mode"
  (command-line-enter-mode search-backward-mode text cursor-pos))

(define/user (exit)
  "Exit the program"
  (scmus-exit 0))

(define/user get-environment-variable
  "Get the value of an environment variable"
  get-environment-variable)

(define/user get-option
  "Get the value of a configuration option"
  get-option)

(define/user (get-char prompt)
  "Prompt the user to enter a character on the command line"
  (call/cc (lambda (return)
             (command-line-get-char prompt return)
             (user-eval-stop))))

(define/user (get-string prompt)
  "Prompt the user to enter a string on the command line"
  (call/cc (lambda (return)
             (command-line-get-string prompt return)
             (user-eval-stop))))

(define/user (load file)
  "Load a Scheme file or command script"
  (cond
    ((string-suffix-ci? ".scm"  file) (user-load file))
    ((string-suffix-ci? ".scmd" file) (load-command-script file)))
  (void))

(define/user mixramp-db
  "Get the current mixramp-db value"
  scmus-mixrampdb)

(define/user mixramp-delay
  "Get the current mixramp-delay value"
  scmus-mixrampdelay)

(define/user mpd-address
  "Get the address of the MPD server"
  scmus-address)

(define/user mpd-host
  "Get the hostname of the MPD server"
  scmus-hostname)

(define/user mpd-port
  "Get the port of the MPD server"
  scmus-port)

(define/user next
  "Play the next track in the queue"
  (return-void scmus-next!))
(user-synonym next! next)

(define/user next-id
  "Get the ID of the next track in the queue"
  scmus-next-song-id)

(define/user next-pos
  "Get the position of the next track in the queue"
  scmus-next-song)

(define/user pause
  "Pause the current track"
  (return-void scmus-toggle-pause!))
(user-synonym pause! pause)

(define/user (play #!optional (track-or-pos (current-track)))
  "Play the current track"
  (cond
    ((and (list? track-or-pos)
          (>= (track-id track-or-pos) 0))
      (scmus-play-id! (track-id track-or-pos)))
    ((integer? track-or-pos)
      (scmus-play-pos! track-or-pos)))
  (void))
(user-synonym play! play)

(define/user playlist-clear
  "Clear the given playlist"
  (return-void scmus-playlist-clear!))
(user-synonym playlist-clear! playlist-clear)

(define/user playlist-add
  "Add a track to the given playlist"
  (return-void scmus-playlist-add!))
(user-synonym playlist-add! playlist-add)

(define/user playlist-move
  "Move a track in the given playlist"
  (return-void scmus-playlist-move!))
(user-synonym playlist-move! playlist-move)

(define/user playlist-delete
  "Delete a track in the given playlist"
  (return-void scmus-playlist-delete!))
(user-synonym playlist-delete! playlist-delete)

(define/user playlist-save
  "Save the current contents of the queue as a playlist"
  (return-void scmus-playlist-save!))
(user-synonym playlist-save! playlist-save)

(define/user playlist-load
  "Load the given playlist into the queue"
  (return-void scmus-playlist-load!))
(user-synonym playlist-load! playlist-load)

(define/user playlist-edit
  "Load the given playlist into the playlist editor"
  (return-void scmus-playlist-edit))

(define/user playlist-rename
  "Rename the given playlist"
  (return-void scmus-playlist-rename!))
(user-synonym playlist-rename! playlist-rename)

(define/user playlist-rm
  "Delete the given playlist"
  (return-void scmus-playlist-rm!))
(user-synonym playlist-rm! playlist-rm)

(define/user prev
  "Play the previous track in the queue"
  (return-void scmus-prev!))
(user-synonym prev! prev)

(define/user queue-delete
  "Delete a track from the queue"
  (return-void scmus-delete!))
(user-synonym queue-delete! queue-delete)

(define/user queue-delete-id
  "Delete a track from the queue by ID"
  (return-void scmus-delete-id!))
(user-synonym queue-delete-id! queue-delete-id)

(define/user queue-length
  "Get the length of the queue"
  scmus-queue-length)

(define/user queue-move
  "Move a track in the queue"
  (return-void scmus-move!))
(user-synonym queue-move! queue-move)

(define/user queue-move-id
  "Move a track in the queue by ID"
  (return-void scmus-move-id!))
(user-synonym queue-move-id! queue-move-id)

(define/user queue-swap
  "Swap tracks in the queue"
  (return-void scmus-swap!))
(user-synonym queue-swap! queue-swap)

(define/user queue-swap-id
  "Swap tracks in the queue by ID"
  (return-void scmus-swap-id!))
(user-synonym queue-swap-id! queue-swap-id)

(define/user queue-version
  "Get the queue version"
  scmus-queue-version)

(define/user (quit)
  "Quit scmus"
  (command-line-get-char "Quit scmus? [y/N] "
    (lambda (c)
      (case c
        ((#\y #\Y) (scmus-exit 0))))))

(define/user random?
  "Check if MPD is in random mode"
  scmus-random?)

(define/user random-set
  "Set random mode on or off"
  (return-void scmus-random-set!))
(user-synonym random-set! random-set)

(define/user refresh-library
  "Refresh the library view's data"
  (thunk (signal-event/global 'db-changed)))
(user-synonym refresh-library! refresh-library)

(define/user (register-command name handler #!optional force?)
  "Register a procedure to handle a command"
  (if (and (not force?)
           (command-exists? name))
    #f
    (begin (register-command! name handler) #t)))
(user-synonym register-command! register-command)

(define/user (register-event-handler event handler)
  "Register an event handler"
  (when (member event *user-events*)
    (add-listener/global event handler))
  (void))
(user-synonym register-event-handler! register-event-handler)

(define/user repeat?
  "Check if MPD is in repeat mode"
  scmus-repeat?)

(define/user repeat-set
  "Set repeat mode on or off"
  (return-void scmus-repeat-set!))
(user-synonym repeat-set! repeat-set)

(define/user (rescan #!optional (path #f))
  "Rescan the music database"
  (scmus-rescan!)
  (void))
(user-synonym rescan! rescan)

(define/user (scmus-format fmt #!optional (track '()) (len (- (COLS) 2)))
  "Generate formatted text"
  (if (format-string-valid? fmt)
    (scmus-format (compile-format-string fmt) len track)
    (raise
      (make-composite-condition
        (make-property-condition 'exn 'message "invalid format string"
                                 'arguments fmt)
        (make-property-condition 'scmus)))))

(define/user seek
  "Seek forwards or backwards in the current track"
  (return-void scmus-seek!))
(user-synonym seek! seek)

(define/user set-color
  "Change the RGB value of a terminal color"
  (return-void set-color))

(define/user set-option
  "Set the value of an option"
  (return-void set-option!))
(user-synonym set-option! set-option)

(define/user set-view
  "Change the current view"
  (return-void set-view!))
(user-synonym set-view! set-view)

(define/user set-volume
  "Set the volume"
  (return-void set-volume!))
(user-synonym set-volume! set-volume)

(define+user (shell command . args)
  "Run a shell command"
  (process-fork
    (lambda ()
      (handle-exceptions exn (void)
        (process-execute command args)))))
(user-synonym shell! shell)

(define+user (shell-sync command . args)
  "Run a shell command synchronously"
  (nth-value 2 (process-wait (apply shell command args))))
(user-synonym shell-sync! shell-sync)

(define/user (shell-term command . args)
  "Run a shell command synchronously, with curses off"
  (without-curses
    (apply shell-sync command args)))
(user-synonym shell-term! shell-term)

;; Spawn a shell command, capturing STDOUT and STDERR as input ports.
;; XXX: the returned ports MUST be closed by the caller.
(define (async-shell! command . args)
  (let-values (((stdout-in stdout-out) (create-pipe))
               ((stderr-in stderr-out) (create-pipe)))
    (let ((child (process-fork
                   (lambda ()
                     (duplicate-fileno stdout-out fileno/stdout)
                     (duplicate-fileno stderr-out fileno/stderr)
                     (file-close stdout-out)
                     (file-close stderr-out)
                     (file-close stdout-in)
                     (file-close stderr-in)
                     (handle-exceptions exn (void)
                       (process-execute command args)))))
          (stdout-in-port (open-input-file* stdout-in))
          (stderr-in-port (open-input-file* stderr-in)))
      (file-close stdout-out)
      (file-close stderr-out)
      (values child stdout-in-port stderr-in-port))))

;; Wrapper for ASYNC-SHELL! that automatically closes pipes.
(define (call-with-shell proc command . args)
  (let-values (((pid stdout stderr) (apply async-shell! command args)))
    (let ((ret (proc pid stdout stderr)))
      (file-close (port->fileno stdout))
      (file-close (port->fileno stderr))
      ret)))

(define/user (shell/capture-stdout command . args)
  "Run a shell command, returning the contents of standard output as a string"
  (apply call-with-shell
    (lambda (pid stdout stderr)
      (with-output-to-string
        (lambda ()
          (let loop ()
            (unless (eof-object? (peek-char stdout))
              (write-char (read-char stdout))
              (loop))))))
    command args))
(user-synonym shell!/capture-stdout shell/capture-stdout)

(define/user shuffle
  "Shuffle the queue"
  (return-void scmus-shuffle!))
(user-synonym shuffle! shuffle)

(define/user single?
  "Check if MPD is in single mode"
  scmus-single?)

(define/user single-set
  "Set single mode on or off"
  (return-void scmus-single-set!))
(user-synonym single-set! single-set)

(define/user (start-timer thunk seconds #!key (recurring #f))
  "Start a timer to run a thunk after a number of seconds"
  (let ((event (gensym)))
    (register-event-handler! event thunk)
    (register-timer-event! event seconds recurring: recurring)))
(user-synonym start-timer! start-timer)

(define/user state
  "Get the current player state"
  scmus-state)

(define/user stop
  "Stop playing"
  (return-void scmus-stop!))
(user-synonym stop! stop)

(define/user toggle-consume
  "Toggle consume mode"
  (return-void scmus-toggle-consume!))
(user-synonym toggle-consume! toggle-consume)

(define/user toggle-random
  "Toggle random mode"
  (return-void scmus-toggle-random!))
(user-synonym toggle-random! toggle-random)

(define/user toggle-repeat
  "Toggle repeat mode"
  (return-void scmus-toggle-repeat!))
(user-synonym toggle-repeat! toggle-repeat)

(define/user toggle-single
  "Toggle single mode"
  (return-void scmus-toggle-single!))
(user-synonym toggle-single! toggle-single)

(define/user track-album
  "Get the album from a track object"
  track-album)

(define/user track-albumartist
  "Get the albumartist from a track object"
  track-albumartist)

(define/user track-artist
  "Get the artist from a track object"
  track-artist)

(define/user track-composer
  "Get the composer from a track object"
  track-composer)

(define/user track-date
  "Get the date from a track object"
  track-date)

(define/user track-disc 
  "Get the disc from a track object"
  track-disc)

(define/user track-duration
  "Get the duration from a track object"
  track-duration)

(define/user track-end
  "Get the end from a track object"
  track-end)

(define/user track-file
  "Get the file from a track object"
  track-file)

(define/user track-genre
  "Get the genre from a track object"
  track-genre)

(define/user track-id
  "Get the ID from a track object"
  track-id)

(define/user track-last-modified
  "Get the last-modified date from a track object"
  track-last-modified)

(define/user track-name
  "Get the name from a track object"
  track-name)

(define/user track-performer
  "Get the performer from a track object"
  track-performer)

(define/user track-pos
  "Get the position from a track object"
  track-pos)

(define/user track-prio
  "Get the prio from a track object"
  track-prio)

(define/user track-start
  "Get the start from a track object"
  track-start)

(define/user track-title
  "Get the title from a track object"
  track-title)

(define/user track-track
  "Get the track number from a track object"
  track-track)

(define/user (unbind keys context)
  "Unbind a key sequence"
  (let ((key-list (string-tokenize keys)))
    (if (binding-keys-valid? key-list)
      (unbind! key-list context)
      #f)))
(user-synonym unbind! unbind)

(define/user (update #!optional (path #f))
  "Update the music database"
  (scmus-update! path)
  (void))
(user-synonym update! update)

(define/user (win-move n #!optional relative)
  "Move the cursor up or down"
  (widget-move (widget-focus view-widget) n relative))
(user-synonym win-move! win-move)

(define/user (win-bottom)
  "Move the cursor to the bottom of the window"
  (widget-move-bottom (widget-focus view-widget)))
(user-synonym win-bottom! win-bottom)

(define/user (win-top)
  "Move the cursor to the top of the window"
  (widget-move-top (widget-focus view-widget)))
(user-synonym win-top! win-top)

(define/user (win-activate)
  "Activate the row at the cursor"
  (widget-activate (widget-focus view-widget)))
(user-synonym win-activate! win-activate)

(define/user (win-deactivate)
  "Deactivate the window"
  (widget-deactivate (widget-focus view-widget)))
(user-synonym win-deactivate! win-deactivate)

(define/user (win-add #!optional (dst 'queue))
  "Add the selected row"
  (widget-add (widget-focus view-widget) dst))
(user-synonym win-add! win-add)

(define/user (win-remove)
  "Remove the selected row"
  (widget-remove (widget-focus view-widget)))
(user-synonym win-remove! win-remove)

(define/user (win-clear)
  "Clear the current window"
  (widget-clear (widget-focus view-widget)))
(user-synonym win-clear! win-clear)

(define/user (win-paste #!optional (before #f))
  "Move the marked tracks to the cursor"
  (widget-paste (widget-focus view-widget) before))
(user-synonym win-move-trakcs  win-paste)
(user-synonym win-move-tracks! win-paste)

(define+user (win-search query #!optional backward?)
  "Search the current window"
  (current-search-query query)
  (searching-backward? backward?)
  (widget-search (widget-focus view-widget)
                 (current-search-query)
                 backward?))
(user-synonym win-search! win-search)

(define+user (win-search-next)
  "Move the cursor to the next search result"
  (when (current-search-query)
    (widget-search (widget-focus view-widget)
                   (current-search-query)
                   (searching-backward?))))
(user-synonym win-search-next! win-search-next)

(define+user (win-search-prev)
  "Move the cursor to the previous search result"
  (when (current-search-query)
    (widget-search (widget-focus view-widget)
                   (current-search-query)
                   (not (searching-backward?)))))
(user-synonym win-search-prev! win-search-prev)

(define/user (win-edit)
  "Edit the selected row"
  (widget-edit (widget-focus view-widget)))
(user-synonym win-edit! win-edit)

(define/user (win-mark)
  "Mark the selected row"
  (widget-mark (widget-focus view-widget)))
(user-synonym win-mark! win-mark)

(define/user (win-unmark)
  "Unmark the selected row"
  (widget-unmark (widget-focus view-widget)))
(user-synonym win-unmark! win-unmark)

(define/user (win-toggle-mark)
  "Toggle the marked status of the selected row"
  (widget-toggle-mark (widget-focus view-widget)))
(user-synonym win-toggle-mark! win-toggle-mark)

(define/user (win-clear-marked)
  "Unmark all marked rows"
  (widget-clear-marked (widget-focus view-widget)))
(user-synonym win-clear-marked! win-clear-marked)

(define/user (win-selected)
  "Get the current selection data"
  (widget-data (widget-focus view-widget)))

(define/user write-config
  "Write the current configuration settings to a file"
  (return-void write-config!))
(user-synonym write-config! write-config)

(define/user xfade
  "Get the value of the xfade setting"
  scmus-xfade)

;; SRFI-13 {{{

(export-identifier! string?)
(export-identifier! string-null?)
(export-identifier! string-every)
(export-identifier! string-any)
(export-identifier! make-string)
(export-identifier! string)
(export-identifier! string-tabulate)
(export-identifier! string->list)
(export-identifier! list->string)
(export-identifier! reverse-list->string)
(export-identifier! string-join)
(export-identifier! string-length)
(export-identifier! string-ref)
(export-identifier! string-copy)
(export-identifier! substring/shared)
(export-identifier! string-copy!)
(export-identifier! string-take)
(export-identifier! string-drop)
(export-identifier! string-take-right)
(export-identifier! string-drop-right)
(export-identifier! string-pad)
(export-identifier! string-pad-right)
(export-identifier! string-trim)
(export-identifier! string-trim-right)
(export-identifier! string-trim-both)
(export-identifier! string-set!)
(export-identifier! string-fill!)
(export-identifier! string-compare)
(export-identifier! string-compare-ci)
(export-identifier! string=)
(export-identifier! string<>)
(export-identifier! string<)
(export-identifier! string>)
(export-identifier! string<=)
(export-identifier! string>=)
(export-identifier! string-ci=)
(export-identifier! string-ci<>)
(export-identifier! string-ci<)
(export-identifier! string-ci>)
(export-identifier! string-ci<=)
(export-identifier! string-ci>=)
(export-identifier! string-hash)
(export-identifier! string-hash-ci)
(export-identifier! string-prefix-length)
(export-identifier! string-suffix-length)
(export-identifier! string-prefix-length-ci)
(export-identifier! string-suffix-length-ci)
(export-identifier! string-prefix?)
(export-identifier! string-suffix?)
(export-identifier! string-prefix-ci?)
(export-identifier! string-suffix-ci?)
(export-identifier! string-index)
(export-identifier! string-index-right)
(export-identifier! string-skip)
(export-identifier! string-skip-right)
(export-identifier! string-count)
(export-identifier! string-contains)
(export-identifier! string-contains-ci)
(export-identifier! string-titlecase)
(export-identifier! string-titlecase!)
(export-identifier! string-upcase)
(export-identifier! string-upcase!)
(export-identifier! string-downcase)
(export-identifier! string-downcase!)
(export-identifier! string-reverse)
(export-identifier! string-reverse!)
(export-identifier! string-append)
(export-identifier! string-concatenate)
(export-identifier! string-concatenate/shared)
(export-identifier! string-append/shared)
(export-identifier! string-concatenate-reverse)
(export-identifier! string-concatenate-reverse/shared)
(export-identifier! string-map)
(export-identifier! string-map!)
(export-identifier! string-fold)
(export-identifier! string-fold-right)
(export-identifier! string-unfold)
(export-identifier! string-unfold-right)
(export-identifier! string-for-each)
(export-identifier! string-for-each-index)
(export-identifier! xsubstring)
(export-identifier! string-xcopy!)
(export-identifier! string-replace)
(export-identifier! string-tokenize)
(export-identifier! string-filter)
(export-identifier! string-delete)
(export-identifier! string-parse-start+end)
(export-identifier! string-parse-final-start+end)
(export-identifier! check-substring-spec)
(export-identifier! substring-spec-ok?)
(export-identifier! make-kmp-restart-vector)
(export-identifier! kmp-step)
(export-identifier! string-kmp-partial-search)

;; SRFI-13 }}}
;; procedures }}}
