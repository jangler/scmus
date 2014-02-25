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
               option)
         (export *current-input-mode*
                 *current-view*
                 curses-print
                 print-command-line-char
                 ui-element-changed!
                 curses-update
                 cursor-on
                 cursor-off
                 set-input-mode!
                 handle-input
                 init-curses
                 exit-curses))

(define *current-input-mode* 'normal-mode)
(define *current-view* 'browser)

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
    (mvaddstr line 1 left)
    (clrtoeol)
    (mvaddstr line
              (- (COLS) (string-length right) 1)
              right)))

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
  (format-print-line (- (LINES) 2)
                     (get-option 'format-status)
                     *current-track*))

(define (update-current-line)
  (format-print-line (- (LINES) 3)
                     (get-option 'format-current)
                     *current-track*))

(define (update-queue)
  (let ((max-lines (- (LINES) 4)))
    (define (*update-queue queue lines)
      (when (and (> lines 0)
                 (not (null? queue)))
        (format-print-line (- max-lines (- lines 1))
                           (get-option 'format-queue)
                           (car queue))
        (*update-queue (cdr queue) (- lines 1))))
    (*update-queue *queue* max-lines)))

(define *ui-elements-changed* '())
(define *ui-update-functions*
  (list (cons 'command-line update-command-line)
        (cons 'status-line update-status-line)
        (cons 'current-line update-current-line)
        (cons 'queue update-queue)))

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
