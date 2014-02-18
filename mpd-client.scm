
(declare (unit mpd-client))

(include "libmpdclient.scm")

(define (mpd:connect host port)
  (mpd_connection_new host port 500))

(define (mpd:disconnect connection)
  (mpd_connection_free connection))

(define (mpd:reconnect connection)
  (let* ((settings (mpd_connection_get_settings connection))
         (host (mpd_settings_get_host settings))
         (port (mpd_settings_get_port settings)))
    (mpd_connection_free connection)
    (mpd:connect host port)))

(define (mpd:raise-error code)
  (abort (make-property-condition 'mpd 'code code)))

(define (mpd:get-stats connection)
  (let* ((stats (mpd_run_stats connection))
         (error (mpd_connection_get_error connection))
         (retval
           (if stats
             (list
               (cons 'artists (mpd_stats_get_number_of_artists stats))
               (cons 'albums (mpd_stats_get_number_of_albums stats))
               (cons 'songs (mpd_stats_get_number_of_songs stats))
               (cons 'uptime (mpd_stats_get_uptime stats))
               (cons 'db-update (mpd_stats_get_db_update_time stats))
               (cons 'playtime (mpd_stats_get_play_time stats))
               (cons 'db-playtime (mpd_stats_get_db_play_time stats)))
             '())))
     (if stats
       (mpd_stats_free stats))
     (when (not (= error MPD_ERROR_SUCCESS))
       (curses-print (mpd_connection_get_error_message connection))
       (mpd:raise-error error))
     retval))

(define (mpd-state->symbol state)
  (cond
    ((= state MPD_STATE_UNKNOWN) 'unknown)
    ((= state MPD_STATE_STOP) 'stop)
    ((= state MPD_STATE_PLAY) 'play)
    ((= state MPD_STATE_PAUSE) 'pause)))

(define (mpd:get-status connection)
  (let* ((status (mpd_run_status connection))
         (error (mpd_connection_get_error connection))
         (retval
           (if status
             (list
               (cons 'volume (mpd_status_get_volume status))
               (cons 'repeat (mpd_status_get_repeat status))
               (cons 'random (mpd_status_get_random status))
               (cons 'single (mpd_status_get_single status))
               (cons 'consume (mpd_status_get_consume status))
               (cons 'queue-length (mpd_status_get_queue_length status))
               (cons 'queue-version (mpd_status_get_queue_version status))
               (cons 'state (mpd-state->symbol
                              (mpd_status_get_state status)))
               (cons 'xfade (mpd_status_get_crossfade status))
               (cons 'mixrampdb (mpd_status_get_mixrampdb status))
               (cons 'mixrampdelay (mpd_status_get_mixrampdelay status))
               (cons 'song-pos (mpd_status_get_song_pos status))
               (cons 'song-id (mpd_status_get_song_id status))
               (cons 'next-song-pos (mpd_status_get_next_song_pos status))
               (cons 'next-song-id (mpd_status_get_next_song_id status))
               (cons 'elapsed-time (mpd_status_get_elapsed_time status))
               (cons 'elapsed-ms (mpd_status_get_elapsed_ms status))
               (cons 'total-time (mpd_status_get_total_time status))
               (cons 'bitrate (mpd_status_get_kbit_rate status))
               ; TODO: audio format
               (cons 'updating (= 1 (mpd_status_get_update_id status)))
               (cons 'error (mpd_status_get_error status)))
             '())))
    (if status
      (mpd_status_free status))
    (when (not (= error MPD_ERROR_SUCCESS))
      (curses-print (string-append "STATUS: " (mpd_connection_get_error_message connection)))
      (mpd:raise-error error))
    retval))

(define (mpd:get-current-song connection)
  (let* ((song (mpd_run_current_song connection))
         (error (mpd_connection_get_error connection))
         (retval
           (if song
             (list
               (cons 'file (mpd_song_get_uri song))
               (cons 'artist (mpd_song_get_tag song MPD_TAG_ARTIST 0))
               (cons 'album (mpd_song_get_tag song MPD_TAG_ALBUM 0))
               (cons 'albumartist
                     (mpd_song_get_tag song MPD_TAG_ALBUM_ARTIST 0))
               (cons 'title (mpd_song_get_tag song MPD_TAG_TITLE 0))
               (cons 'track (mpd_song_get_tag song MPD_TAG_TRACK 0))
               (cons 'name (mpd_song_get_tag song MPD_TAG_NAME 0))
               (cons 'genre (mpd_song_get_tag song MPD_TAG_GENRE 0))
               (cons 'date (mpd_song_get_tag song MPD_TAG_DATE 0))
               (cons 'composer (mpd_song_get_tag song MPD_TAG_COMPOSER 0))
               (cons 'performer (mpd_song_get_tag song MPD_TAG_PERFORMER 0))
               (cons 'comment (mpd_song_get_tag song MPD_TAG_COMMENT 0))
               (cons 'disc (mpd_song_get_tag song MPD_TAG_DISC 0))
               (cons 'duration (mpd_song_get_duration song))
               (cons 'start (mpd_song_get_start song))
               (cons 'end (mpd_song_get_end song))
               (cons 'last-modified (mpd_song_get_last_modified song))
               (cons 'pos (mpd_song_get_pos song))
               (cons 'id (mpd_song_get_id song))
               (cons 'prio (mpd_song_get_prio song))
               )
             '())))
    (if song
      (mpd_song_free song))
    (when (not (= error MPD_ERROR_SUCCESS))
      (curses-print (mpd_connection_get_error_message connection))
      (mpd:raise-error error))
    retval))

(define mpd:play! mpd_run_play)
(define mpd:pause! mpd_run_toggle_pause)
(define mpd:stop! mpd_run_stop)
(define mpd:next-song! mpd_run_next)
(define mpd:previous-song! mpd_run_previous)
