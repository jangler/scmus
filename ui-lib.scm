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

(import drewt.ncurses)
(import scmus.base scmus.format scmus.option scmus.tui)

(: separator? (* -> boolean))
(define (separator? row)
  (and (pair? row) (eqv? (car row) 'separator)))

(define (alist->kv-rows alist)
  (map (lambda (pair)
         `(key-value . ((key   . ,(car pair))
                        (value . ,(cdr pair)))))
       alist))

(define *key-value-format* (process-format "~-50%{key} ~{value}"))
