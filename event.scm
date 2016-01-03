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

(require-extension srfi-18)

(declare (unit event)
         (export handle-events!
                 register-event!
                 register-event-handler!
                 register-timer!
                 register-timer-event!))

(: *events* (list-of symbol))
(define *events* '())

(: *event-handlers* (list-of (pair symbol thunk)))
(define *event-handlers* '())

(: register-event! (symbol -> undefined))
(define (register-event! event)
  (set! *events* (cons event *events*)))

(: register-event-handler! (symbol thunk -> undefined))
(define (register-event-handler! event handler #!key (run-first #f))
  (let* ((old-handlers (alist-ref event *event-handlers* eqv? '()))
         (new-handlers (if run-first
                         (cons handler old-handlers)
                         (append! old-handlers (list handler)))))
    (set! *event-handlers*
      (alist-update! event new-handlers *event-handlers*))))

(: handle-events! thunk)
(define (handle-events!)
  (define (handle-event event)
    (let loop ((handlers (reverse (alist-ref event *event-handlers* eqv? '()))))
      (unless (null? handlers)
        ((car handlers))
        (loop (cdr handlers)))))
  (handle-timers)
  ;; XXX: Events may trigger other events, so we need to loop until the queue
  ;;      is really empty.  To avoid hanging in the case where multiple events
  ;;      endlessly trigger each other, we specify a maximum recursion depth
  ;;      and discard all pending events when it's reached.
  (let loop ((events *events*) (i 0))
    (set! *events* '())
    (if (> i 10)
      (error-set! (make-property-condition 'exn
                    'message "handle-events! reached depth limit"
                    'arguments events))
      (begin
        (for-each handle-event events)
        (unless (null? *events*)
          (loop *events* (+ i 1)))))))

(define *timers* '())

(define timer-expire-time car)
(define timer-thunk cdr)

(define (register-timer! thunk seconds #!key (recurring #f))
  (define (make-timer)
    (cons (+ (time->seconds (current-time))
           seconds)
        (if recurring
          (rec (recurring-thunk)
            (thunk)
            (register-timer! recurring-thunk seconds))
          thunk)))
  (set! *timers* (append! *timers* (list (make-timer)))))

(define (register-timer-event! name . rest)
  (apply register-timer! (lambda () (register-event! name)) rest))

(define (handle-timers)
  (let ((ct (time->seconds (current-time))))
    (let loop ((timers *timers*) (thunks '()))
      (if (or (null? timers)
              (> (timer-expire-time (car timers)) ct))
        (begin
          (set! *timers* timers)
          (for-each (lambda (thunk) (thunk)) (reverse thunks)))
        (loop (cdr timers)
              (cons (cdar timers) thunks))))))
