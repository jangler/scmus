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

(module scmus.config (*verbose*
                      *debug*
                      *scmus-dir*
                      *version*
                      *home-dir*
                      *user-config-dir*
                      *plugins-dir*
                      *sysrc-path*
                      *scmusrc-path*)
  (import scheme chicken foreign)

  (define *verbose* #f)
  (define *debug* #t)

  (define *scmus-dir* (foreign-value SCMUS_DIR c-string))
  (define *version* (foreign-value VERSION c-string))

  (define (get-env-default name default)
    (let ((env (get-environment-variable name)))
     (if env env default)))

  (define *home-dir* (get-env-default "HOME" "."))
  (define *user-config-dir*
    (string-append (get-env-default "XDG_CONFIG_HOME"
                                    (string-append *home-dir* "/.config"))
                   "/scmus"))
  (define *plugins-dir* (string-append *scmus-dir* "/plugins"))

  (define *sysrc-path* (string-append *scmus-dir* "/scmusrc.scm"))
  (define *scmusrc-path* (string-append *user-config-dir* "/rc.scm")))
