;;
;; Copyright 2014 Drew Thoreson
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

(require-extension ncurses)

(declare (unit ui-curses)
         (uses scmus-client
               eval-mode
               search-mode
               command-line
               keys
               format
               option
               window)
         (export *current-input-mode*
                 *current-view*
                 win-move!
                 win-activate!
                 curses-print
                 print-command-line-char
                 register-event!
                 curses-update
                 cursor-on
                 cursor-off
                 set-input-mode!
                 handle-input
                 init-curses
                 exit-curses))

;;; definitions missing from the ncurses egg
(define bkgdset
  (foreign-lambda* void ((unsigned-long a0)) "bkgdset(a0);"))
(define use_default_colors
  (foreign-lambda* integer () "return(use_default_colors());"))

(define-constant CURSED-CMDLINE 0)
(define-constant CURSED-ERROR 1)
(define-constant CURSED-INFO 2)
(define-constant CURSED-SEPARATOR 3)
(define-constant CURSED-STATUSLINE 4)
(define-constant CURSED-TITLELINE 5)
(define-constant CURSED-WIN 6)
(define-constant CURSED-WIN-CUR 7)
(define-constant CURSED-WIN-CUR-SEL 8)
(define-constant CURSED-WIN-INACTIVE-CUR-SEL 9)
(define-constant CURSED-WIN-INACTIVE-SEL 10)
(define-constant CURSED-WIN-SEL 11)
(define-constant CURSED-WIN-TITLE 12)
(define-constant NR-CURSED 13)

(define *current-input-mode* 'normal-mode)
(define *current-view* 'queue)

;; alist associating views and windows
(define *windows*
  '((queue . #f)
    (library . #f)))

;; can only be used *after* ncurses initialized
(define-syntax make-track-window
  (syntax-rules ()
    ((make-track-window track-list changed-event)
      (make-window #f
                   (lambda (x) track-list)
                   (length track-list)
                   0
                   0
                   (- (LINES) 4)
                   (lambda (w)
                     (register-event! changed-event))
                   (lambda (w)
                     (scmus-play-track! (window-selected w)))))))

(define (current-window)
  (alist-ref *current-view* *windows*))

(define (win-move! nr-lines)
  (if (> nr-lines 0)
    (window-move-down! (current-window) nr-lines)
    (window-move-up! (current-window) (abs nr-lines))))

(define (win-activate!)
  (window-activate! (current-window)))

(define-syntax let-format
  (syntax-rules ()
    ((let-format ((left right) fmt track len) body ...)
      (let* ((left-right (scmus-format fmt len track))
             (left (car left-right))
             (right (cdr left-right)))
        body ...))
    ((let-format ((left right) fmt track) body ...)
      (let-format ((left right) fmt track (- (COLS) 2))
        body ...))
    ((let-format ((left right) fmt) body ...)
      (let-format ((left right) fmt *current-track*)
        body ...))))

(define (format-print-line line fmt track)
  (let-format ((left right) fmt track)
    (mvaddch line 0 #\space)
    (addstr left)
    (clrtoeol)
    (mvaddstr line
              (- (COLS) (string-length right) 1)
              right)))

(define (curses-print str)
  (mvaddstr 0 0 str))

(define (print-command-line-char ch)
  (cursed-set! CURSED-CMDLINE)
  (mvaddch (- (LINES) 1) 0 ch))

(define (update-command-line)
  (cursed-set! CURSED-CMDLINE)
  (move (- (LINES) 1) 1)
  (clrtoeol)
  (addstr (string-truncate (command-line-text)
                           (- (COLS) 2))))

(define (update-cursor)
  (move (- (LINES) 1) (command-line-cursor-pos)))

(define (update-status-line)
  (cursed-set! CURSED-STATUSLINE)
  (format-print-line (- (LINES) 2)
                     (get-option 'format-status)
                     *current-track*))

(define (update-current-line)
  (cursed-set! CURSED-TITLELINE)
  (format-print-line (- (LINES) 3)
                     (get-option 'format-current)
                     *current-track*))

(define (update-track-window window title-fmt track-fmt)
  (let ((nr-lines (window-nr-lines window)))
    (define (*update-track-window track-list lines)
      (when (> lines 0)
        (let ((line-nr (- nr-lines (- lines 1)))
              (next (if (null? track-list) '() (cdr track-list))))
          (if (null? track-list)
            (begin (move line-nr 1) (clrtoeol))
            (format-print-line line-nr track-fmt (car track-list)))
          (*update-track-window next (- lines 1)))))
    (cursed-set! CURSED-WIN-TITLE)
    (format-print-line 0 title-fmt '())
    (cursed-set! CURSED-WIN)
    (*update-track-window (window-top window) nr-lines)
    (cursed-set! CURSED-WIN-SEL)
    (format-print-line (+ 1 (- (window-sel-pos window)
                               (window-top-pos window)))
                       track-fmt
                       (window-selected window))))

(define (update-queue)
  (update-track-window (alist-ref 'queue *windows*)
                       (get-option 'format-queue-title)
                       (get-option 'format-queue)))

(define *events* '())
(define *event-handlers*
  (list (cons 'command-line-changed update-command-line)
        (cons 'status-line-changed update-status-line)
        (cons 'current-line-changed update-current-line)
        (cons 'queue-changed update-queue)))

(define (register-event! event)
  (set! *events* (cons event *events*)))

(define (curses-update)
  (for-each (lambda (x)
              ((alist-ref x *event-handlers*)))
            *events*)
  (update-cursor)
  (set! *events* '()))

(define (handle-resize)
  #f
  )

(define (cursor-on)
  (curs_set 1))

(define (cursor-off)
  (curs_set 0))

(define (set-input-mode! mode)
  (case mode
    ((normal-mode) (enter-normal-mode))
    ((eval-mode) (enter-eval-mode))
    ((search-mode) (enter-search-mode)))
  (set! *current-input-mode* mode))

(define (handle-key key)
  (case *current-input-mode*
    ((normal-mode)  (normal-mode-key key))
    ((eval-mode) (eval-mode-key key))
    ((search-mode)  (search-mode-key key))))

(define (handle-char ch)
  (case *current-input-mode*
    ((normal-mode)  (normal-mode-char ch))
    ((eval-mode) (eval-mode-char ch))
    ((search-mode)  (search-mode-char ch))))

(define (handle-input)
  (let ((ch (getch)))
    (cond
      ((key= ch ERR)        #f)
      ((key= ch KEY_RESIZE) (handle-resize))
      ((key? ch)            (handle-key ch))
      (else                 (handle-char ch)))))

;; colors {{{

(define (color-symbol->number sym)
  (case sym
    ((default)       -1)
    ((black)         COLOR_BLACK)
    ((red)           COLOR_RED)
    ((green)         COLOR_GREEN)
    ((yellow)        COLOR_YELLOW)
    ((blue)          COLOR_BLUE)
    ((magenta)       COLOR_MAGENTA)
    ((cyan)          COLOR_CYAN)
    ((white)         COLOR_WHITE)
    ((dark-gray)     8)
    ((light-red)     9)
    ((light-green)   10)
    ((light-yellow)  11)
    ((light-blue)    12)
    ((light-magenta) 13)
    ((light-cyan)    14)
    ((gray)          15)
    (else            -1)))

(define *colors* (make-vector NR-CURSED))

(define (colors-set! cursed attr bg fg)
  (vector-set! *colors* cursed (list attr bg fg)))

(define (get-color-option name)
  (let ((option (get-option name)))
    (if (symbol? option)
      (color-symbol->number option)
      option)))

(define (cursed-pair cursed)
  (+ 1 cursed))

(define (cursed-attr cursed)
  (car (vector-ref *colors* cursed)))

(define (cursed-bg cursed)
  (cadr (vector-ref *colors* cursed)))

(define (cursed-fg cursed)
  (caddr (vector-ref *colors* cursed)))

(define (init-cursed! cursed attr bg fg)
  (colors-set! cursed
               (get-option attr)
               (get-color-option bg)
               (get-color-option fg)))

(define (init-colors!)
  (init-cursed! CURSED-CMDLINE
                'color-cmdline-attr
                'color-cmdline-bg
                'color-cmdline-fg)
  (init-cursed! CURSED-ERROR
                'color-cmdline-attr
                'color-cmdline-bg
                'color-error)
  (init-cursed! CURSED-INFO
                'color-cmdline-attr
                'color-cmdline-bg
                'color-cmdline-fg)
  (init-cursed! CURSED-SEPARATOR
                'color-win-attr
                'color-win-bg
                'color-separator)
  (init-cursed! CURSED-STATUSLINE
                'color-statusline-attr
                'color-statusline-bg
                'color-statusline-fg)
  (init-cursed! CURSED-TITLELINE
                'color-titleline-attr
                'color-titleline-bg
                'color-titleline-fg)
  (init-cursed! CURSED-WIN
                'color-win-attr
                'color-win-bg
                'color-win-fg)
  (init-cursed! CURSED-WIN-CUR
                'color-win-attr
                'color-win-bg
                'color-win-cur)
  (init-cursed! CURSED-WIN-CUR-SEL
                'color-win-cur-sel-attr
                'color-win-cur-sel-bg
                'color-win-cur-sel-fg)
  (init-cursed! CURSED-WIN-INACTIVE-CUR-SEL
                'color-win-inactive-cur-sel-attr
                'color-win-inactive-cur-sel-bg
                'color-win-inactive-cur-sel-fg)
  (init-cursed! CURSED-WIN-INACTIVE-SEL
                'color-win-inactive-sel-attr
                'color-win-inactive-sel-bg
                'color-win-inactive-sel-fg)
  (init-cursed! CURSED-WIN-SEL
                'color-win-sel-attr
                'color-win-sel-bg
                'color-win-sel-fg)
  (init-cursed! CURSED-WIN-TITLE
                'color-win-title-attr
                'color-win-title-bg
                'color-win-title-fg)
  (update-colors!)
  (cursed-set! CURSED-WIN))

(define (cursed-set! cursed)
  (bkgdset (COLOR_PAIR (cursed-pair cursed))))

(define (update-colors!)
  (define (*update-colors! i)
    (when (< i NR-CURSED)
      (init_pair (cursed-pair i) (cursed-fg i) (cursed-bg i))
      (*update-colors! (+ i 1))))
  (*update-colors! 0))

;; colors }}}

(define (init-curses)
  (initscr)
  (cbreak)
  (keypad (stdscr) #t)
  (halfdelay 5)
  (noecho)
  (start_color)
  (use_default_colors)
  (init-colors!)
  (alist-update! 'queue
                 (make-track-window *queue* 'queue-changed)
                 *windows*))

(define (exit-curses)
  (handle-exceptions exn
    (void)
    (endwin)))
