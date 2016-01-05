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

(declare (unit search-view)
         (uses editable event format input ncurses option scmus-client ui-lib
               view window)
         (export make-search-view search-edit! search-clear! search-add!
                 search-remove!))

(: search-changed! (#!rest * -> undefined))
(define (search-changed! . ignore)
  (widget-damaged! (get-view 'search)))

(: search-edit! (window -> undefined))
(define (search-edit! window)
  (let ((selected (window-selected window)))
    (when (eqv? (car selected) 'input)
      (set-input-mode! 'edit-mode
                       (cdadr selected)
                       (cons (+ 1 (window-sel-offset window))
                             3)))))

(: add-search-field! (window -> undefined))
(define (add-search-field! window)
  (let-values (((queries results) (search-window-data window)))
    (set! (*window-data window) (append queries
                                        (list (make-search-field)
                                              '(separator . ((text . "Results"))))
                                        results))
    (when (>= (window-sel-pos window) (length queries))
      (window-move-down! window 1))
    (search-changed!)))

(: add-selected-tracks! (window -> undefined))
(define (add-selected-tracks! window)
  (for-each (lambda (x)
              (if (eqv? (car x) 'file)
                (scmus-add! (track-file (cdr x)))))
            (window-all-selected window)))

(: search-add! (window -> undefined))
(define (search-add! window)
  (let ((selected (window-selected window)))
    (case (car selected)
      ((input) (add-search-field! window))
      ((file)  (add-selected-tracks! window)))))

(: search-remove! (window -> undefined))
(define (search-remove! window)
  (let-values (((prev rest) (split-at (*window-data window)
                                      (window-sel-pos window))))
    (cond
      ((null? prev) (editable-clear! (cdadar rest)))
      ((separator? (car rest)) (void))
      (else
        (set! (*window-data window) (append prev (cdr rest)))))
    (search-changed!)))

(: search-clear! (window -> undefined))
(define (search-clear! window)
  (let loop ((data (window-data window)) (result '()))
    (if (or (null? data) (eqv? (caar data) 'file))
      (set! (*window-data window) (reverse result))
      (loop (cdr data) (cons (car data) result))))
  (search-changed!))

(: search-window-data (window -> *))
(define (search-window-data window)
  (let loop ((data (window-data window)) (result '()))
    (if (not (eqv? (caar data) 'input))
      (values (reverse result) (cdr data))
      (loop (cdr data) (cons (car data) result)))))

(: string->tag (string -> (or symbol boolean)))
(define (string->tag str)
  (let ((tag (string->symbol (string-downcase str))))
    (if (memv tag
            '(artist album albumartist title tracknumber name genre date
              composer performer comment discnumber))
      tag
      #f)))

(: parse-constraint (string -> (pair symbol string)))
(define (parse-constraint str)
  (let ((index (string-index str #\:)))
    (if index
      (let ((tag (string->tag (string-take str index))))
        (if tag
          (cons tag (string-drop str (+ 1 index)))
          (cons 'any str)))
      (cons 'any str))))

(: search-activate! (window -> undefined))
(define (search-activate! window)
  (define (gather-constraints)
    (map (lambda (x) (parse-constraint (editable-text (cdadr x))))
         (remove (lambda (x) (= 0 (editable-length (cdadr x))))
                 (search-window-data window))))
  (let ((results (apply scmus-search-songs #f #f (gather-constraints))))
    (set! (*window-data window) (append (window-data window)
                                        (list-of 'file results))))
  (search-changed!))

(: make-search-field (-> (pair symbol (list-of (pair symbol editable)))))
(define (make-search-field)
  `(input . ((text . ,(make-simple-editable
                        (lambda (e) #t)
                        (lambda (e) (set-input-mode! 'normal-mode))
                        search-changed!)))))

(: search-match (* string -> boolean))
(define (search-match row query)
  (and (eqv? (car row) 'file) (track-match (cdr row) query)))

(define *input-format* (process-format "* ~{text}"))

(: search-window-print-row (window * fixnum -> string))
(define (search-window-print-row window row nr-cols)
  (define (row-format tag)
    (case tag
      ((input)     *input-format*)
      ((separator) (get-format 'format-separator))
      ((file)      (get-format 'format-search-file)))) 
  (scmus-format (row-format (car row)) nr-cols (cdr row)))

(define-view search
  (make-view (make-window 'data       (list (make-search-field)
                                            '(separator . ((text . "Results"))))
                          'activate   search-activate!
                          'match      search-match
                          'add        search-add!
                          'remove     search-remove!
                          'clear      search-clear!
                          'edit       search-edit!
                          'print-line search-window-print-row)
             " Search"))
