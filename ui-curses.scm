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
               normal-mode
               command-mode
               search-mode
               command-line
               format))

;; the exit routine; initially (exit), becomes a continuation
(define scmus-exit exit)

(define *current-input-mode* 'normal-mode)

(define *status-line-format*
  (process-format (string->list "~P ~p / ~d - ~T vol: ~v")))

(define *current-line-format*
  (process-format (string->list "~a - ~l ~n. ~t~= ~y")))

(define (curses-print str)
  (mvaddstr 0 0 str))

(define (print-command-line-char ch)
  (mvaddch (- (LINES) 1) 0 ch))

(define (update-command-line)
  (move (- (LINES) 1) 1)
  (clrtoeol)
  (addstr (string-truncate (command-line-text)
                           (- (COLS) 2))))

(define (update-cursor)
  (move (- (LINES) 1) (command-line-cursor-pos)))

(define (update-status-line)
  (let* ((status (scmus-format *status-line-format*
                               (- (COLS) 2)
                               *current-track*))
         (left   (car status))
         (right  (cdr status)))
    (mvaddstr (- (LINES) 2) 1 left)
    (clrtoeol)
    (mvaddstr (- (LINES) 2)
              (- (COLS) (string-length right) 1)
              right)))

(define (update-current-line)
  (let* ((current (scmus-format *current-line-format*
                                (- (COLS) 2)
                                *current-track*))
          (left   (car current))
          (right  (cdr current)))
    (mvaddstr (- (LINES) 3) 1 left)
    (clrtoeol)
    (mvaddstr (- (LINES) 3)
              (- (COLS) (string-length right) 1)
              right)))

(define *ui-elements-changed* '())
(define *ui-update-functions*
  (list (cons 'command-line update-command-line)
        (cons 'status-line update-status-line)
        (cons 'current-line update-current-line)))

(define (ui-element-changed! sym)
  (set! *ui-elements-changed*
        (cons sym *ui-elements-changed*)))

(define (curses-update)
  (for-each (lambda (x)
              ((alist-ref x *ui-update-functions*)))
            *ui-elements-changed*)
  (update-cursor)
  (set! *ui-elements-changed* '()))

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
    ((command-mode) (enter-command-mode))
    ((search-mode) (enter-search-mode)))
  (set! *current-input-mode* mode))

;; Equality predicate for characters and ncurses keycodes.
;; This is necessary because the ncurses egg has KEY_* constants as integers
;; for some reason.
(define (key= ch key)
  (eqv? ch (integer->char key)))

;; #t if ch is not a printable character
(define (key? ch)
  (> (char->integer ch) 255))

(define (handle-key key)
  (case *current-input-mode*
    ((normal-mode)  (normal-mode-key key))
    ((command-mode) (command-mode-key key))
    ((search-mode)  (search-mode-key key))))

(define (handle-char ch)
  (case *current-input-mode*
    ((normal-mode)  (normal-mode-char ch))
    ((command-mode) (command-mode-char ch))
    ((search-mode)  (search-mode-char ch))))

(define (handle-input)
  (let ((ch (getch)))
    (cond
      ((key= ch ERR)        #f)
      ((key= ch KEY_RESIZE) (handle-resize))
      ((key? ch)            (handle-key ch))
      (else                 (handle-char ch)))))

(define (start-color)
  #f
  )

(define (update-colors)
  #f
  )

(define (init-curses)
  (initscr)
  (cbreak)
  (keypad (stdscr) #t)
  (halfdelay 5)
  (noecho)
  (start-color)
  (update-colors))

(define (exit-curses)
  (endwin))
