;;
;; Copyright 2014-2017 Drew Thoreson
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

(declare (unit status)
         (uses track))

(module status (current-queue
                current-status
                current-stats
                current-track
                current-track?
                scmus-volume
                scmus-repeat?
                scmus-random?
                scmus-single?
                scmus-consume?
                scmus-queue-version
                scmus-queue-length
                scmus-state
                scmus-song
                scmus-song-id
                scmus-next-song
                scmus-next-song-id
                scmus-elapsed-time
                scmus-elapsed
                scmus-bitrate
                scmus-xfade
                scmus-mixrampdb
                scmus-mixrampdelay
                scmus-updating-db
                scmus-uptime
                scmus-playtime
                scmus-artists
                scmus-albums
                scmus-songs
                scmus-db-playtime
                scmus-db-update)
  (import scmus-base track)

  (define-syntax define/getter-setter
    (syntax-rules ()
      ((define/getter-setter name initval)
        (define name
          (let ((local initval))
            (getter-with-setter
              (lambda () local)
              (lambda (x) (set! local x))))))))

  (define/getter-setter current-status '())
  (define/getter-setter current-stats '())
  (define/getter-setter current-track '())
  (define/getter-setter current-queue '())

  (: current-track? (track -> boolean))
  (define (current-track? track)
    (track= track (current-track)))

  (define-syntax status-selector
    (syntax-rules ()
      ((status-selector name sym)
        (status-selector name sym ""))
      ((status-selector name sym default)
        (define (name)
          (let ((e (alist-ref sym (current-status))))
            (if e e default))))))

  (define-syntax stat-selector
    (syntax-rules ()
      ((stat-selector name sym)
        (stat-selector name sym 0))
      ((stat-selector name sym default)
        (define (name)
          (let ((e (alist-ref sym (current-stats))))
            (if e e default))))))

  (status-selector scmus-volume 'volume 0)
  (status-selector scmus-repeat? 'repeat #f)
  (status-selector scmus-random? 'random #f)
  (status-selector scmus-single? 'single #f)
  (status-selector scmus-consume? 'consume #f)
  (status-selector scmus-queue-version 'playlist 0)
  (status-selector scmus-queue-length 'playlistlength 0)
  (status-selector scmus-state 'state 'unknown)
  (status-selector scmus-song 'song -1)
  (status-selector scmus-song-id 'songid -1)
  (status-selector scmus-next-song 'nextsong 0)
  (status-selector scmus-next-song-id 'nextsongid 0)
  (status-selector scmus-elapsed-time 'time '(0))
  (status-selector scmus-elapsed 'elapsed 0)
  (status-selector scmus-bitrate 'bitrate 0)
  (status-selector scmus-xfade 'xfade 0)
  (status-selector scmus-mixrampdb 'mixrampdb 0.0)
  (status-selector scmus-mixrampdelay 'mixrampdelay 0.0)
  (status-selector scmus-updating-db 'updating_db)
  ;(status-selector scmus-total-time 'total-time 0)
  ;(status-selector scmus-audio 'audio '(0 0 0))

  (stat-selector scmus-uptime 'uptime)
  (stat-selector scmus-playtime 'playtime)
  (stat-selector scmus-artists 'artists)
  (stat-selector scmus-albums 'albums)
  (stat-selector scmus-songs 'songs)
  (stat-selector scmus-db-playtime 'db_playtime)
  (stat-selector scmus-db-update 'db_update))