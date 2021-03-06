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

(module scmus.error (scmus-error)
  (import (only extras pretty-print)
          scmus.base
          scmus.command-line
          scmus.log)

  (define scmus-error
    (make-parameter #f
      (lambda (error)
        (if (not error)
          ""
          (let* ((out (open-output-string))
                 (emsg (get-condition-property error 'exn 'message "Error"))
                 (args (get-condition-property error 'exn 'arguments #f))
                 (msg (if args (format "~a: ~s" emsg args) emsg)))
            (pretty-print (condition->list error) out)
            (log-write! 'error msg (string-trim-both (get-output-string out)))
            (if ((condition-predicate 'exn) error)
              (command-line-print-error! msg))
            (get-output-string out)))))))
