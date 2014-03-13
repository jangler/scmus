
;;; GENERATED BY CHICKEN-BIND FROM libmpdclient.h

(begin
  (define mpd_pair-name
    (foreign-lambda*
      c-string
      (((c-pointer (struct "mpd_pair")) s))
      "return(s->name);"))
  (define mpd_pair-value
    (foreign-lambda*
      c-string
      (((c-pointer (struct "mpd_pair")) s))
      "return(s->value);"))
  (define make-mpd_pair
    (foreign-lambda*
      (c-pointer (struct "mpd_pair"))
      ((c-string name) (c-string value))
      "struct mpd_pair *tmp_ =  (struct mpd_pair *)C_malloc(sizeof(struct mpd_pair));\ntmp_->name = name;\ntmp_->value = value;\nreturn(tmp_);;\n"))
  (define-constant MPD_SERVER_ERROR_UNK -1)
  (define-constant MPD_SERVER_ERROR_NOT_LIST 1)
  (define-constant MPD_SERVER_ERROR_ARG 2)
  (define-constant MPD_SERVER_ERROR_PASSWORD 3)
  (define-constant MPD_SERVER_ERROR_PERMISSION 4)
  (define-constant MPD_SERVER_ERROR_UNKNOWN_CMD 5)
  (define-constant MPD_SERVER_ERROR_NO_EXIST 50)
  (define-constant MPD_SERVER_ERROR_PLAYLIST_MAX 51)
  (define-constant MPD_SERVER_ERROR_SYSTEM 52)
  (define-constant MPD_SERVER_ERROR_PLAYLIST_LOAD 53)
  (define-constant MPD_SERVER_ERROR_UPDATE_ALREADY 54)
  (define-constant MPD_SERVER_ERROR_PLAYER_SYNC 55)
  (define-constant MPD_SERVER_ERROR_EXIST 56)
  (define-constant MPD_ERROR_SUCCESS 0)
  (define-constant MPD_ERROR_OOM 1)
  (define-constant MPD_ERROR_ARGUMENT 2)
  (define-constant MPD_ERROR_STATE 3)
  (define-constant MPD_ERROR_TIMEOUT 4)
  (define-constant MPD_ERROR_SYSTEM 5)
  (define-constant MPD_ERROR_RESOLVER 6)
  (define-constant MPD_ERROR_MALFORMED 7)
  (define-constant MPD_ERROR_CLOSED 8)
  (define-constant MPD_ERROR_SERVER 9)
  (define-constant MPD_STATE_UNKNOWN 0)
  (define-constant MPD_STATE_STOP 1)
  (define-constant MPD_STATE_PLAY 2)
  (define-constant MPD_STATE_PAUSE 3)
  (define-constant MPD_TAG_UNKNOWN -1)
  (define-constant MPD_TAG_ARTIST 0)
  (define-constant MPD_TAG_ALBUM 1)
  (define-constant MPD_TAG_ALBUM_ARTIST 2)
  (define-constant MPD_TAG_TITLE 3)
  (define-constant MPD_TAG_TRACK 4)
  (define-constant MPD_TAG_NAME 5)
  (define-constant MPD_TAG_GENRE 6)
  (define-constant MPD_TAG_DATE 7)
  (define-constant MPD_TAG_COMPOSER 8)
  (define-constant MPD_TAG_PERFORMER 9)
  (define-constant MPD_TAG_COMMENT 10)
  (define-constant MPD_TAG_DISC 11)
  (define-constant MPD_TAG_MUSICBRAINZ_ARTISTID 12)
  (define-constant MPD_TAG_MUSICBRAINZ_ALBUMID 13)
  (define-constant MPD_TAG_MUSICBRAINZ_ALBUMARTISTID 14)
  (define-constant MPD_TAG_MUSICBRAINZ_TRACKID 15)
  (define-constant MPD_TAG_COUNT 16)
  (define-constant MPD_ENTITY_TYPE_UNKNOWN 0)
  (define-constant MPD_ENTITY_TYPE_DIRECTORY 1)
  (define-constant MPD_ENTITY_TYPE_SONG 2)
  (define-constant MPD_ENTITY_TYPE_PLAYLIST 3)
  (define-constant MPD_OPERATOR_DEFAULT 0)
  (begin
    (define mpd_settings_new
      (foreign-lambda*
        (c-pointer (struct "mpd_settings"))
        ((c-string a0)
         (unsigned-integer a1)
         (unsigned-integer a2)
         (c-string a3)
         (c-string a4))
        "return(mpd_settings_new(a0 , a1 , a2 , a3 , a4));")))
  (begin
    (define mpd_settings_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_settings")) a0))
        "mpd_settings_free(a0);")))
  (begin
    (define mpd_settings_get_host
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_settings")) a0))
        "return(mpd_settings_get_host(a0));")))
  (begin
    (define mpd_settings_get_port
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_settings")) a0))
        "return(mpd_settings_get_port(a0));")))
  (begin
    (define mpd_settings_get_timeout_ms
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_settings")) a0))
        "return(mpd_settings_get_timeout_ms(a0));")))
  (begin
    (define mpd_settings_get_password
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_settings")) a0))
        "return(mpd_settings_get_password(a0));")))
  (begin
    (define mpd_connection_new
      (foreign-lambda*
        (c-pointer (struct "mpd_connection"))
        ((c-string a0) (unsigned-integer a1) (unsigned-integer a2))
        "return(mpd_connection_new(a0 , a1 , a2));")))
  (begin
    (define mpd_connection_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_connection")) a0))
        "mpd_connection_free(a0);")))
  (begin
    (define mpd_connection_get_settings
      (foreign-lambda*
        (c-pointer (const (struct "mpd_settings")))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_get_settings(a0));")))
  (begin
    (define mpd_connection_get_error
      (foreign-lambda*
        (enum "mpd_error")
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_get_error(a0));")))
  (begin
    (define mpd_connection_get_error_message
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_get_error_message(a0));")))
  (begin
    (define mpd_connection_get_server_error
      (foreign-lambda*
        (enum "mpd_server_error")
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_get_server_error(a0));")))
  (begin
    (define mpd_connection_get_system_error
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_get_system_error(a0));")))
  (begin
    (define mpd_connection_clear_error
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_connection_clear_error(a0));")))
  (begin
    (define mpd_run_current_song
      (foreign-lambda*
        (c-pointer (struct "mpd_song"))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_current_song(a0));")))
  (begin
    (define mpd_run_play
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_play(a0));")))
  (begin
    (define mpd_run_play_pos
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_play_pos(a0 , a1));")))
  (begin
    (define mpd_run_play_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_play_id(a0 , a1));")))
  (begin
    (define mpd_run_stop
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_stop(a0));")))
  (begin
    (define mpd_run_toggle_pause
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_toggle_pause(a0));")))
  (begin
    (define mpd_run_pause
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_run_pause(a0 , a1));")))
  (begin
    (define mpd_run_next
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_next(a0));")))
  (begin
    (define mpd_run_previous
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_previous(a0));")))
  (begin
    (define mpd_run_seek_pos
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_seek_pos(a0 , a1 , a2));")))
  (begin
    (define mpd_run_seek_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_seek_id(a0 , a1 , a2));")))
  (begin
    (define mpd_run_repeat
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_run_repeat(a0 , a1));")))
  (begin
    (define mpd_run_random
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_run_random(a0 , a1));")))
  (begin
    (define mpd_run_single
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_run_single(a0 , a1));")))
  (begin
    (define mpd_run_consume
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_run_consume(a0 , a1));")))
  (begin
    (define mpd_run_crossfade
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_crossfade(a0 , a1));")))
  (begin
    (define mpd_run_mixrampdb
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (float a1))
        "return(mpd_run_mixrampdb(a0 , a1));")))
  (begin
    (define mpd_run_mixrampdelay
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (float a1))
        "return(mpd_run_mixrampdelay(a0 , a1));")))
  (begin
    (define mpd_run_clearerror
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_clearerror(a0));")))
  (begin
    (define mpd_run_status
      (foreign-lambda*
        (c-pointer (struct "mpd_status"))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_status(a0));")))
  (begin
    (define mpd_status_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_status")) a0))
        "mpd_status_free(a0);")))
  (begin
    (define mpd_status_get_volume
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_volume(a0));")))
  (begin
    (define mpd_status_get_repeat
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_repeat(a0));")))
  (begin
    (define mpd_status_get_random
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_random(a0));")))
  (begin
    (define mpd_status_get_single
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_single(a0));")))
  (begin
    (define mpd_status_get_consume
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_consume(a0));")))
  (begin
    (define mpd_status_get_queue_length
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_queue_length(a0));")))
  (begin
    (define mpd_status_get_queue_version
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_queue_version(a0));")))
  (begin
    (define mpd_status_get_state
      (foreign-lambda*
        (enum "mpd_state")
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_state(a0));")))
  (begin
    (define mpd_status_get_crossfade
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_crossfade(a0));")))
  (begin
    (define mpd_status_get_mixrampdb
      (foreign-lambda*
        float
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_mixrampdb(a0));")))
  (begin
    (define mpd_status_get_mixrampdelay
      (foreign-lambda*
        float
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_mixrampdelay(a0));")))
  (begin
    (define mpd_status_get_song_pos
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_song_pos(a0));")))
  (begin
    (define mpd_status_get_song_id
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_song_id(a0));")))
  (begin
    (define mpd_status_get_next_song_pos
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_next_song_pos(a0));")))
  (begin
    (define mpd_status_get_next_song_id
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_next_song_id(a0));")))
  (begin
    (define mpd_status_get_elapsed_time
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_elapsed_time(a0));")))
  (begin
    (define mpd_status_get_elapsed_ms
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_elapsed_ms(a0));")))
  (begin
    (define mpd_status_get_total_time
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_total_time(a0));")))
  (begin
    (define mpd_status_get_kbit_rate
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_kbit_rate(a0));")))
  (begin
    (define mpd_status_get_audio_format
      (foreign-lambda*
        (c-pointer (const (struct "mpd_audio_format")))
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_audio_format(a0));")))
  (begin
    (define mpd_status_get_update_id
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_update_id(a0));")))
  (begin
    (define mpd_status_get_error
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_status")) a0))
        "return(mpd_status_get_error(a0));")))
  (begin
    (define mpd_run_stats
      (foreign-lambda*
        (c-pointer (struct "mpd_stats"))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_stats(a0));")))
  (begin
    (define mpd_stats_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_stats")) a0))
        "mpd_stats_free(a0);")))
  (begin
    (define mpd_stats_get_number_of_artists
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_number_of_artists(a0));")))
  (begin
    (define mpd_stats_get_number_of_albums
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_number_of_albums(a0));")))
  (begin
    (define mpd_stats_get_number_of_songs
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_number_of_songs(a0));")))
  (begin
    (define mpd_stats_get_uptime
      (foreign-lambda*
        unsigned-long
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_uptime(a0));")))
  (begin
    (define mpd_stats_get_db_update_time
      (foreign-lambda*
        unsigned-long
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_db_update_time(a0));")))
  (begin
    (define mpd_stats_get_play_time
      (foreign-lambda*
        unsigned-long
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_play_time(a0));")))
  (begin
    (define mpd_stats_get_db_play_time
      (foreign-lambda*
        unsigned-long
        (((c-pointer (struct "mpd_stats")) a0))
        "return(mpd_stats_get_db_play_time(a0));")))
  (begin
    (define mpd_tag_name
      (foreign-lambda* c-string ((long a0)) "return(mpd_tag_name(a0));")))
  (begin
    (define mpd_tag_name_parse
      (foreign-lambda*
        long
        ((c-string a0))
        "return(mpd_tag_name_parse(a0));")))
  (begin
    (define mpd_tag_name_iparse
      (foreign-lambda*
        long
        ((c-string a0))
        "return(mpd_tag_name_iparse(a0));")))
  (begin
    (define mpd_song_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_song")) a0))
        "mpd_song_free(a0);")))
  (begin
    (define mpd_song_get_uri
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_uri(a0));")))
  (begin
    (define mpd_song_get_tag
      (foreign-lambda*
        c-string
        (((c-pointer (struct "mpd_song")) a0) (long a1) (unsigned-integer a2))
        "return(mpd_song_get_tag(a0 , a1 , a2));")))
  (begin
    (define mpd_song_get_duration
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_duration(a0));")))
  (begin
    (define mpd_song_get_start
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_start(a0));")))
  (begin
    (define mpd_song_get_end
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_end(a0));")))
  (begin
    (define mpd_song_get_last_modified
      (foreign-lambda*
        unsigned-long
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_last_modified(a0));")))
  (begin
    (define mpd_song_set_pos
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_song")) a0) (unsigned-integer a1))
        "mpd_song_set_pos(a0 , a1);")))
  (begin
    (define mpd_song_get_pos
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_pos(a0));")))
  (begin
    (define mpd_song_get_id
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_id(a0));")))
  (begin
    (define mpd_song_get_prio
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_song")) a0))
        "return(mpd_song_get_prio(a0));")))
  (begin
    (define mpd_song_begin
      (foreign-lambda*
        (c-pointer (struct "mpd_song"))
        (((c-pointer (struct "mpd_pair")) a0))
        "return(mpd_song_begin(a0));")))
  (begin
    (define mpd_song_feed
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_song")) a0)
         ((c-pointer (struct "mpd_pair")) a1))
        "return(mpd_song_feed(a0 , a1));")))
  (begin
    (define mpd_recv_song
      (foreign-lambda*
        (c-pointer (struct "mpd_song"))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_recv_song(a0));")))
  (begin
    (define mpd_send_list_queue_meta
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_send_list_queue_meta(a0));")))
  (begin
    (define mpd_send_list_queue_range_meta
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_send_list_queue_range_meta(a0 , a1 , a2));")))
  (begin
    (define mpd_run_get_queue_song_pos
      (foreign-lambda*
        (c-pointer (struct "mpd_song"))
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_get_queue_song_pos(a0 , a1));")))
  (begin
    (define mpd_run_get_queue_song_id
      (foreign-lambda*
        (c-pointer (struct "mpd_song"))
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_get_queue_song_id(a0 , a1));")))
  (begin
    (define mpd_send_queue_changes_meta
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_send_queue_changes_meta(a0 , a1));")))
  (begin
    (define mpd_run_add
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_run_add(a0 , a1));")))
  (begin
    (define mpd_run_add_id
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_run_add_id(a0 , a1));")))
  (begin
    (define mpd_run_add_id_to
      (foreign-lambda*
        integer
        (((c-pointer (struct "mpd_connection")) a0)
         (c-string a1)
         (unsigned-integer a2))
        "return(mpd_run_add_id_to(a0 , a1 , a2));")))
  (begin
    (define mpd_run_delete
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_delete(a0 , a1));")))
  (begin
    (define mpd_run_delete_range
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_delete_range(a0 , a1 , a2));")))
  (begin
    (define mpd_run_delete_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_run_delete_id(a0 , a1));")))
  (begin
    (define mpd_run_shuffle
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_shuffle(a0));")))
  (begin
    (define mpd_run_shuffle_range
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_shuffle_range(a0 , a1 , a2));")))
  (begin
    (define mpd_run_clear
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_run_clear(a0));")))
  (begin
    (define mpd_run_move
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_move(a0 , a1 , a2));")))
  (begin
    (define mpd_run_move_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_move_id(a0 , a1 , a2));")))
  (begin
    (define mpd_run_move_range
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2)
         (unsigned-integer a3))
        "return(mpd_run_move_range(a0 , a1 , a2 , a3));")))
  (begin
    (define mpd_run_swap
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_swap(a0 , a1 , a2));")))
  (begin
    (define mpd_run_swap_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2))
        "return(mpd_run_swap_id(a0 , a1 , a2));")))
  (begin
    (define mpd_run_prio
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (integer a1)
         (unsigned-integer a2))
        "return(mpd_run_prio(a0 , a1 , a2));")))
  (begin
    (define mpd_run_prio_range
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (integer a1)
         (unsigned-integer a2)
         (unsigned-integer a3))
        "return(mpd_run_prio_range(a0 , a1 , a2 , a3));")))
  (begin
    (define mpd_run_prio_id
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (integer a1)
         (unsigned-integer a2))
        "return(mpd_run_prio_id(a0 , a1 , a2));")))
  (begin
    (define mpd_search_db_songs
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_search_db_songs(a0 , a1));")))
  (begin
    (define mpd_search_add_db_songs
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_search_add_db_songs(a0 , a1));")))
  (begin
    (define mpd_search_queue_songs
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (bool a1))
        "return(mpd_search_queue_songs(a0 , a1));")))
  (begin
    (define mpd_search_db_tags
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_search_db_tags(a0 , a1));")))
  (begin
    (define mpd_count_db_songs
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_count_db_songs(a0));")))
  (begin
    (define mpd_search_add_base_constraint
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (c-string a2))
        "return(mpd_search_add_base_constraint(a0 , a1 , a2));")))
  (begin
    (define mpd_search_add_uri_constraint
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (c-string a2))
        "return(mpd_search_add_uri_constraint(a0 , a1 , a2));")))
  (begin
    (define mpd_search_add_tag_constraint
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (unsigned-integer a2)
         (c-string a3))
        "return(mpd_search_add_tag_constraint(a0 , a1 , a2 , a3));")))
  (begin
    (define mpd_search_add_any_tag_constraint
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0)
         (unsigned-integer a1)
         (c-string a2))
        "return(mpd_search_add_any_tag_constraint(a0 , a1 , a2));")))
  (begin
    (define mpd_search_commit
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_search_commit(a0));")))
  (begin
    (define mpd_search_cancel
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_connection")) a0))
        "mpd_search_cancel(a0);")))
  (begin
    (define mpd_recv_pair_tag
      (foreign-lambda*
        (c-pointer (struct "mpd_pair"))
        (((c-pointer (struct "mpd_connection")) a0) (unsigned-integer a1))
        "return(mpd_recv_pair_tag(a0 , a1));")))
  (begin
    (define mpd_return_pair
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_connection")) a0)
         ((c-pointer (struct "mpd_pair")) a1))
        "mpd_return_pair(a0 , a1);")))
  (begin
    (define mpd_send_list_all
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_send_list_all(a0 , a1));")))
  (begin
    (define mpd_send_list_all_meta
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_send_list_all_meta(a0 , a1));")))
  (begin
    (define mpd_send_list_meta
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_send_list_meta(a0 , a1));")))
  (begin
    (define mpd_send_read_comments
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_send_read_comments(a0 , a1));")))
  (begin
    (define mpd_run_update
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_run_update(a0 , a1));")))
  (begin
    (define mpd_run_rescan
      (foreign-lambda*
        unsigned-integer
        (((c-pointer (struct "mpd_connection")) a0) (c-string a1))
        "return(mpd_run_rescan(a0 , a1));")))
  (begin
    (define mpd_entity_free
      (foreign-lambda*
        void
        (((c-pointer (struct "mpd_entity")) a0))
        "mpd_entity_free(a0);")))
  (begin
    (define mpd_entity_get_type
      (foreign-lambda*
        (enum "mpd_entity_type")
        (((c-pointer (struct "mpd_entity")) a0))
        "return(mpd_entity_get_type(a0));")))
  (begin
    (define mpd_entity_get_directory
      (foreign-lambda*
        (c-pointer (const (struct "mpd_directory")))
        (((c-pointer (struct "mpd_entity")) a0))
        "return(mpd_entity_get_directory(a0));")))
  (begin
    (define mpd_entity_get_song
      (foreign-lambda*
        (c-pointer (const (struct "mpd_song")))
        (((c-pointer (struct "mpd_entity")) a0))
        "return(mpd_entity_get_song(a0));")))
  (begin
    (define mpd_entity_get_playlist
      (foreign-lambda*
        (c-pointer (const (struct "mpd_playlist")))
        (((c-pointer (struct "mpd_entity")) a0))
        "return(mpd_entity_get_playlist(a0));")))
  (begin
    (define mpd_entity_begin
      (foreign-lambda*
        (c-pointer (struct "mpd_entity"))
        (((c-pointer (struct "mpd_pair")) a0))
        "return(mpd_entity_begin(a0));")))
  (begin
    (define mpd_entity_feed
      (foreign-lambda*
        bool
        (((c-pointer (struct "mpd_entity")) a0)
         ((c-pointer (struct "mpd_pair")) a1))
        "return(mpd_entity_feed(a0 , a1));")))
  (begin
    (define mpd_recv_entity
      (foreign-lambda*
        (c-pointer (struct "mpd_entity"))
        (((c-pointer (struct "mpd_connection")) a0))
        "return(mpd_recv_entity(a0));"))))

;;; END OF FILE
