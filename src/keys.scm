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

;;
;; A "binding list" is an alist associating keys with expressions or other
;; binding lists.  If a key is associated with an expression then the
;; expression is evaluated when the key is pressed.  If a key is associated
;; with a binding list, then scmus enters the context given by that binding
;; list when the key is pressed.
;; 
;; A "context" is a binding list.  When scmus is in the context of a particular
;; binding list, key-presses are interpreted relative to that list.  When a
;; key-press results in an expression being evaluated or a failure to locate a
;; binding, scmus returns to the top-level context from which it came.
;; 
;; The "top-level" contexts are enumerated in the *bindings* alist.  Before any
;; keys are pressed, scmus is in one of the top-level contexts.
;; 

(require-extension srfi-1 srfi-69)

(module scmus.keys (binding-context-valid?
                    binding-data
                    binding-expression
                    binding-expression?
                    binding-key
                    binding-keys-valid?
                    bindings
                    get-binding-expression
                    key-list->string
                    make-binding!
                    normal-mode-key
                    register-context!
                    unbind!

                    LEFT_MOUSE_PRESS
                    LEFT_MOUSE_RELEASE
                    LEFT_MOUSE_CLICK
                    LEFT_MOUSE_DOUBLE_CLICK
                    LEFT_MOUSE_TRIPLE_CLICK
                    RIGHT_MOUSE_PRESS
                    RIGHT_MOUSE_RELEASE
                    RIGHT_MOUSE_CLICK
                    RIGHT_MOUSE_DOUBLE_CLICK
                    RIGHT_MOUSE_TRIPLE_CLICK
                    MIDDLE_MOUSE_PRESS
                    MIDDLE_MOUSE_RELEASE
                    MIDDLE_MOUSE_CLICK
                    MIDDLE_MOUSE_DOUBLE_CLICK
                    MIDDLE_MOUSE_TRIPLE_CLICK
                    SCROLL_WHEEL_DOWN
                    SCROLL_WHEEL_UP)

  (import srfi-69)
  (import scmus.base scmus.ueval scmus.event drewt.ncurses)

  (define-type binding-node (pair string pair))
  (define-type binding-list (list-of binding-node))
  (define-type binding-terminal (pair symbol *))
  (define-type binding-data (or binding-list binding-terminal))

  ;; alist associating key-contexts with binding alists
  (: *bindings* (list-of (pair symbol binding-list)))
  (define *bindings* '((common)))

  (: bindings (-> (list-of (pair symbol binding-list))))
  (define (bindings) *bindings*)

  (define (register-context! name)
    (set! *bindings* (alist-update! name '() *bindings*)))

  (define current-context (make-parameter #f))

  (define common-context (make-parameter #f))

  (: binding-expression? (* -> boolean))
  (define (binding-expression? binding)
    (and (pair? binding) (eqv? (car binding) 'binding)))

  (: binding-key (pair -> string))
  (define (binding-key binding)
    (car binding))

  (: binding-data (pair -> binding-data))
  (define (binding-data binding)
    (cdr binding))

  (: binding-expression (pair -> *))
  (define (binding-expression binding)
    (cdr (binding-data binding)))

  (: get-binding (string binding-list -> (or false binding-data)))
  (define (get-binding key bindings)
    (assert (string? key) "get-binding" key)
    (alist-ref key bindings string=?))

  (: get-binding-expression ((list-of string) symbol -> *))
  (define (get-binding-expression keys context)
    (let loop ((keys keys)
               (key-list (alist-ref context *bindings*)))
      (let ((binding (get-binding (car keys) key-list)))
        (cond
          ; found binding
          ((and (null? (cdr keys))
                (binding-expression? binding))
            (cdr binding))
          ; no binding exists
          ((or (null? (cdr keys))
               (not binding))
            #f)
          ; recursive case
          (else (loop (cdr keys) binding))))))

  ;; Non-destructive binding update.  Binds expr to keys in key-list.
  (: make-binding ((list-of string) binding-list * -> (or binding-list false)))
  (define (make-binding keys key-list expr)
    (let ((binding (get-binding (car keys) key-list)))
      (cond
        ; last key and no conflict: do bind
        ((and (null? (cdr keys))
              (not binding))
          (alist-update (car keys) (cons 'binding expr) key-list string=?))
        ; binding conflict
        ((or (null? (cdr keys))
             (binding-expression? binding))
          #f)
        ; recursive case
        (else
          (let ((new-bindings (make-binding (cdr keys)
                                            (if binding binding '())
                                            expr)))
            (if new-bindings
              (alist-update (car keys) new-bindings key-list string=?)
              #f))))))

  ;; Destructive binding update.  Binds expr to keys in the given context.
  (: make-binding! ((list-of string) symbol * -> boolean))
  (define (make-binding! keys context expr)
    (assert (binding-context-valid? context) "make-binding!" context)
    (let ((new (make-binding keys (alist-ref context *bindings*) expr)))
      (if new
        (begin
          (alist-update! context new *bindings*)
          (signal-event/global 'binding-data-changed)
          #t)
        #f)))

  (: keybind-remove (string binding-list -> binding-list))
  (define (keybind-remove key blist)
    (remove (lambda (x) (string=? (car x) key)) blist))

  (: unbind ((list-of string) binding-list -> binding-list))
  (define (unbind keys key-list)
    (let ((binding (get-binding (car keys) key-list)))
      (cond
        ; base case: remove binding
        ((or (null? (cdr keys))
             (binding-expression? binding))
          (keybind-remove (car keys) key-list))
        ; not bound: do nothing
        ((not binding)
          key-list)
        ; recursive case
        (else
          (let ((new-bindings (unbind (cdr keys) binding)))
            (if (null? new-bindings)
              (keybind-remove (car keys) key-list)
              (alist-update (car keys) new-bindings key-list string=?)))))))

  (: unbind! ((list-of string) symbol -> boolean))
  (define (unbind! keys context)
    (assert (binding-context-valid? context) "unbind!" context)
    (let ((new (unbind keys (alist-ref context *bindings*))))
      (if new
        (begin
          (alist-update! context new *bindings*)
          (signal-event/global 'binding-data-changed)
          #t)
        #f)))

  (: key-list->string ((list-of string) -> string))
  (define (key-list->string keys)
    (fold (lambda (str acc)
            (if acc
              (string-append acc " " str)
              str))
          #f
          keys))

  ;; Converts an ncurses keypress event to a string.
  ;; Argument may be either a character or an integer.
  (: key->string ((or char fixnum) -> (or string false)))
  (define (key->string key)
    (find-key-name (if (char? key)
                     (char->integer key)
                     key)))

  (: binding-keys-valid? (list -> boolean))
  (define (binding-keys-valid? keys)
    (if (null? keys)
      #t
      (and (string? (car keys))
           (key-valid? (car keys))
           (binding-keys-valid? (cdr keys)))))

  (: binding-context-valid? (symbol -> boolean))
  (define (binding-context-valid? context)
    (memv context (map car *bindings*)))

  ;; Abandons the current key context.
  (: clear-context! thunk)
  (define (clear-context!)
    (current-context #f)
    (common-context #f))

  ;; Begins a new key context.  This can be delayed until a key is
  ;; pressed so that new bindings and view changes are taken into
  ;; account.
  (: start-context! (symbol -> undefined))
  (define (start-context! view)
    (current-context (alist-ref view *bindings*))
    (common-context (alist-ref 'common *bindings*)))

  (: normal-mode-key (symbol (or fixnum char) -> undefined))
  (define (normal-mode-key view key)
    (if (not (current-context))
      (start-context! view))
    (let ((keystr (key->string key)))
      (if keystr
        (let ((view-binding (get-binding keystr (current-context)))
              (common-binding (get-binding keystr (common-context)))) 
          (cond
            ((binding-expression? view-binding)
              (user-eval (cdr view-binding))
              (clear-context!))
            ((binding-expression? common-binding)
              (user-eval (cdr common-binding))
              (clear-context!))
            ((or (list? view-binding)
                 (list? common-binding))
              (current-context (if view-binding view-binding '()))
              (common-context (if common-binding common-binding '())))
            (else ; no binding
              (clear-context!)))))))

  (: find-key-code (string -> (or fixnum boolean)))
  (define (find-key-code name)
    (hash-table-ref/default *key-table* name #f))

  (: key-valid? (* -> boolean))
  (define (key-valid? k) (not (not (find-key-code k))))
 
  (: find-key-name (fixnum -> (or string false)))
  (define (find-key-name code)
    (hash-table-fold *key-table*
                     (lambda (key value acc)
                       (if (= code value)
                         key
                         acc))
                     #f))

  (define LEFT_MOUSE_PRESS          -1)
  (define LEFT_MOUSE_RELEASE        -2)
  (define LEFT_MOUSE_CLICK          -3)
  (define LEFT_MOUSE_DOUBLE_CLICK   -4)
  (define LEFT_MOUSE_TRIPLE_CLICK   -5)
  (define RIGHT_MOUSE_PRESS         -6)
  (define RIGHT_MOUSE_RELEASE       -7)
  (define RIGHT_MOUSE_CLICK         -8)
  (define RIGHT_MOUSE_DOUBLE_CLICK  -9)
  (define RIGHT_MOUSE_TRIPLE_CLICK  -10)
  (define MIDDLE_MOUSE_PRESS        -11)
  (define MIDDLE_MOUSE_RELEASE      -12)
  (define MIDDLE_MOUSE_CLICK        -13)
  (define MIDDLE_MOUSE_DOUBLE_CLICK -14)
  (define MIDDLE_MOUSE_TRIPLE_CLICK -15)
  (define SCROLL_WHEEL_DOWN         -16)
  (define SCROLL_WHEEL_UP           -17)

  (: *key-table* hash-table)
  (define *key-table*
    (alist->hash-table 
      `(("left_mouse_press"          . ,LEFT_MOUSE_PRESS)
        ("left_mouse_release"        . ,LEFT_MOUSE_RELEASE)
        ("left_mouse_click"          . ,LEFT_MOUSE_CLICK)
        ("left_mouse_double_click"   . ,LEFT_MOUSE_DOUBLE_CLICK)
        ("left_mouse_triple_click"   . ,LEFT_MOUSE_TRIPLE_CLICK)
        ("right_mouse_press"         . ,RIGHT_MOUSE_PRESS)
        ("right_mouse_release"       . ,RIGHT_MOUSE_RELEASE)
        ("right_mouse_click"         . ,RIGHT_MOUSE_CLICK)
        ("right_mouse_double_click"  . ,RIGHT_MOUSE_DOUBLE_CLICK)
        ("right_mouse_triple_click"  . ,RIGHT_MOUSE_TRIPLE_CLICK)
        ("middle_mouse_press"        . ,MIDDLE_MOUSE_PRESS)
        ("middle_mouse_release"      . ,MIDDLE_MOUSE_RELEASE)
        ("middle_mouse_click"        . ,MIDDLE_MOUSE_CLICK)
        ("middle_mouse_double_click" . ,MIDDLE_MOUSE_DOUBLE_CLICK)
        ("middle_mouse_triple_click" . ,MIDDLE_MOUSE_TRIPLE_CLICK)
        ("scroll_wheel_down"         . ,SCROLL_WHEEL_DOWN)
        ("scroll_wheel_up"           . ,SCROLL_WHEEL_UP)

        ( "!"              . 33)
        ( "\""             . 34)
        ( "#"              . 35)
        ( "$"              . 36)
        ( "%"              . 37)
        ( "&"              . 38)
        ( "'"              . 39)
        ( "("              . 40)
        ( ")"              . 41)
        ( "*"              . 42)
        ( "+"              . 43)
        ( ","              . 44)
        ( "-"              . 45)
        ( "."              . 46)
        ( "/"              . 47)
        ( "0"              . 48)
        ( "1"              . 49)
        ( "2"              . 50)
        ( "3"              . 51)
        ( "4"              . 52)
        ( "5"              . 53)
        ( "6"              . 54)
        ( "7"              . 55)
        ( "8"              . 56)
        ( "9"              . 57)
        ( ":"              . 58)
        ( ";"              . 59)
        ( "<"              . 60)
        ( "="              . 61)
        ( ">"              . 62)
        ( "?"              . 63)
        ( "@"              . 64)
        ( "A"              . 65)
        ( "B"              . 66)
        ( "C"              . 67)
        ( "D"              . 68)
        ( "E"              . 69)
        ( "F"              . 70)
        ( "F1"             . ,(KEY_F 1))
        ( "F10"            . ,(KEY_F 10))
        ( "F11"            . ,(KEY_F 11))
        ( "F12"            . ,(KEY_F 12))
        ( "F2"             . ,(KEY_F 2))
        ( "F3"             . ,(KEY_F 3))
        ( "F4"             . ,(KEY_F 4))
        ( "F5"             . ,(KEY_F 5))
        ( "F6"             . ,(KEY_F 6))
        ( "F7"             . ,(KEY_F 7))
        ( "F8"             . ,(KEY_F 8))
        ( "F9"             . ,(KEY_F 9))
        ( "G"              . 71)
        ( "H"              . 72)
        ( "I"              . 73)
        ( "J"              . 74)
        ( "K"              . 75)
        ( "KP_center"      . ,KEY_B2)
        ( "KP_lower_left"  . ,KEY_C1)
        ( "KP_lower_right" . ,KEY_C3)
        ( "KP_upper_left"  . ,KEY_A1)
        ( "KP_upper_right" . ,KEY_A3)
        ( "L"              . 76)
        ( "M"              . 77)
        ( "M-!"            . 161)
        ( "M-\""           . 162)
        ( "M-#"            . 163)
        ( "M-$"            . 164)
        ( "M-%"            . 165)
        ( "M-&"            . 166)
        ( "M-'"            . 167)
        ( "M-("            . 168)
        ( "M-)"            . 169)
        ( "M-*"            . 170)
        ( "M-+"            . 171)
        ( "M-,"            . 172)
        ( "M--"            . 173)
        ( "M-."            . 174)
        ( "M-/"            . 175)
        ( "M-0"            . 176)
        ( "M-1"            . 177)
        ( "M-2"            . 178)
        ( "M-3"            . 179)
        ( "M-4"            . 180)
        ( "M-5"            . 181)
        ( "M-6"            . 182)
        ( "M-7"            . 183)
        ( "M-8"            . 184)
        ( "M-9"            . 185)
        ( "M-:"            . 186)
        ( "M-;"            . 187)
        ( "M-<"            . 188)
        ( "M-="            . 189)
        ( "M->"            . 190)
        ( "M-?"            . 191)
        ( "M-@"            . 192)
        ( "M-A"            . 193)
        ( "M-B"            . 194)
        ( "M-C"            . 195)
        ( "M-D"            . 196)
        ( "M-E"            . 197)
        ( "M-F"            . 198)
        ( "M-G"            . 199)
        ( "M-H"            . 200)
        ( "M-I"            . 201)
        ( "M-J"            . 202)
        ( "M-K"            . 203)
        ( "M-L"            . 204)
        ( "M-M"            . 205)
        ( "M-N"            . 206)
        ( "M-O"            . 207)
        ( "M-P"            . 208)
        ( "M-Q"            . 209)
        ( "M-R"            . 210)
        ( "M-S"            . 211)
        ( "M-T"            . 212)
        ( "M-U"            . 213)
        ( "M-V"            . 214)
        ( "M-W"            . 215)
        ( "M-X"            . 216)
        ( "M-Y"            . 217)
        ( "M-Z"            . 218)
        ( "M-["            . 219)
        ( "M-\\"           . 220)
        ( "M- "            . 221)
        ( "M-^"            . 222)
        ( "M-^?"           . 255)
        ( "M-^@"           . 128)
        ( "M-^A"           . 129)
        ( "M-^B"           . 130)
        ( "M-^C"           . 131)
        ( "M-^D"           . 132)
        ( "M-^E"           . 133)
        ( "M-^F"           . 134)
        ( "M-^G"           . 135)
        ( "M-^H"           . 136)
        ( "M-^I"           . 137)
        ( "M-^J"           . 138)
        ( "M-^K"           . 139)
        ( "M-^L"           . 140)
        ( "M-^M"           . 141)
        ( "M-^N"           . 142)
        ( "M-^O"           . 143)
        ( "M-^P"           . 144)
        ( "M-^Q"           . 145)
        ( "M-^R"           . 146)
        ( "M-^S"           . 147)
        ( "M-^T"           . 148)
        ( "M-^U"           . 149)
        ( "M-^V"           . 150)
        ( "M-^W"           . 151)
        ( "M-^X"           . 152)
        ( "M-^Y"           . 153)
        ( "M-^Z"           . 154)
        ( "M-^["           . 155)
        ( "M-^\\"          . 156)
        ( "M-^]"           . 157)
        ( "M-^^"           . 158)
        ( "M-^_"           . 159)
        ( "M-_"            . 223)
        ( "M-`"            . 224)
        ( "M-a"            . 225)
        ( "M-b"            . 226)
        ( "M-c"            . 227)
        ( "M-d"            . 228)
        ( "M-e"            . 229)
        ( "M-f"            . 230)
        ( "M-g"            . 231)
        ( "M-h"            . 232)
        ( "M-i"            . 233)
        ( "M-j"            . 234)
        ( "M-k"            . 235)
        ( "M-l"            . 236)
        ( "M-m"            . 237)
        ( "M-n"            . 238)
        ( "M-o"            . 239)
        ( "M-p"            . 240)
        ( "M-q"            . 241)
        ( "M-r"            . 242)
        ( "M-s"            . 243)
        ( "M-space"        . 160)
        ( "M-t"            . 244)
        ( "M-u"            . 245)
        ( "M-v"            . 246)
        ( "M-w"            . 247)
        ( "M-x"            . 248)
        ( "M-y"            . 249)
        ( "M-z"            . 250)
        ( "M-("            . 251)
        ( "M-|"            . 252)
        ( "M-)"            . 253)
        ( "M-~"            . 254)
        ( "N"              . 78)
        ( "O"              . 79)
        ( "P"              . 80)
        ( "Q"              . 81)
        ( "R"              . 82)
        ( "S"              . 83)
        ( "S-begin"        . ,KEY_SBEG)
        ( "S-cancel"       . ,KEY_SCANCEL)
        ( "S-command"      . ,KEY_SCOMMAND)
        ( "S-copy"         . ,KEY_SCOPY)
        ( "S-create"       . ,KEY_SCREATE)
        ( "S-del_line"     . ,KEY_SDL)
        ( "S-delete"       . ,KEY_SDC)
        ( "S-eol"          . ,KEY_SEOL)
        ( "S-exit"         . ,KEY_SEXIT)
        ( "S-find"         . ,KEY_SFIND)
        ( "S-help"         . ,KEY_SHELP)
        ( "S-home"         . ,KEY_SHOME)
        ( "S-insert"       . ,KEY_SIC)
        ( "S-left"         . ,KEY_SLEFT)
        ( "S-message"      . ,KEY_SMESSAGE)
        ( "S-move"         . ,KEY_SMOVE)
        ( "S-next"         . ,KEY_SNEXT)
        ( "S-options"      . ,KEY_SOPTIONS)
        ( "S-previous"     . ,KEY_SPREVIOUS)
        ( "S-print"        . ,KEY_SPRINT)
        ( "S-redo"         . ,KEY_SREDO)
        ( "S-replace"      . ,KEY_SREPLACE)
        ( "S-resume"       . ,KEY_SRSUME)
        ( "S-right"        . ,KEY_SRIGHT)
        ( "S-save"         . ,KEY_SSAVE)
        ( "S-suspend"      . ,KEY_SSUSPEND)
        ( "S-undo"         . ,KEY_SUNDO)
        ( "T"              . 84)
        ( "U"              . 85)
        ( "V"              . 86)
        ( "W"              . 87)
        ( "X"              . 88)
        ( "Y"              . 89)
        ( "Z"              . 90)
        ( "["              . 91)
        ( "\\"             . 92)
        ( "]"              . 93)
        ( "^"              . 94)
        ( "^A"             . 1)
        ( "^B"             . 2)
        ( "^C"             . 3)
        ( "^D"             . 4)
        ( "^E"             . 5)
        ( "^F"             . 6)
        ( "^G"             . 7)
        ( "^H"             . 8)
        ( "^K"             . 11)
        ( "^L"             . 12)
        ( "^M"             . 13)
        ( "^N"             . 14)
        ( "^O"             . 15)
        ( "^P"             . 16)
        ( "^Q"             . 17)
        ( "^R"             . 18)
        ( "^S"             . 19)
        ( "^T"             . 20)
        ( "^U"             . 21)
        ( "^V"             . 22)
        ( "^W"             . 23)
        ( "^X"             . 24)
        ( "^Y"             . 25)
        ( "^Z"             . 26)
        ( "^\\"            . 28)
        ( "^ "             . 29)
        ( "^^"             . 30)
        ( "^_"             . 31)
        ( "_"              . 95)
        ( "`"              . 96)
        ( "a"              . 97)
        ( "b"              . 98)
        ( "back_tab"       . ,KEY_BTAB)
        ( "backspace"      . ,KEY_BACKSPACE) ; NOTE: both key and ch
        ( "begin"          . ,KEY_BEG)
        ( "c"              . 99)
        ( "cancel"         . ,KEY_CANCEL)
        ( "clear"          . ,KEY_CLEAR)
        ( "clear_all_tabs" . ,KEY_CATAB)
        ( "clear_tab"      . ,KEY_CTAB)
        ( "close"          . ,KEY_CLOSE)
        ( "command"        . ,KEY_COMMAND)
        ( "copy"           . ,KEY_COPY)
        ( "create"         . ,KEY_CREATE)
        ( "d"              . 100)
        ( "del_line"       . ,KEY_DL)
        ( "delete"         . ,KEY_DC)
        ( "down"           . ,KEY_DOWN)
        ( "e"              . 101)
        ( "eic"            . ,KEY_EIC)
        ( "end"            . ,KEY_END)
        ( "enter"          . 10)
        ( "eol"            . ,KEY_EOL)
        ( "eos"            . ,KEY_EOS)
        ( "exit"           . ,KEY_EXIT)
        ( "f"              . 102)
        ( "find"           . ,KEY_FIND)
        ( "g"              . 103)
        ( "h"              . 104)
        ( "help"           . ,KEY_HELP)
        ( "home"           . ,KEY_HOME)
        ( "i"              . 105)
        ( "ins_line"       . ,KEY_IL)
        ( "insert"         . ,KEY_IC)
        ( "j"              . 106)
        ( "k"              . 107)
        ( "l"              . 108)
        ( "left"           . ,KEY_LEFT)
        ( "lower_left"     . ,KEY_LL)
        ( "m"              . 109)
        ( "mark"           . ,KEY_MARK)
        ( "message"        . ,KEY_MESSAGE)
        ( "move"           . ,KEY_MOVE)
        ( "n"              . 110)
        ( "next"           . ,KEY_NEXT)
        ( "o"              . 111)
        ( "open"           . ,KEY_OPEN)
        ( "options"        . ,KEY_OPTIONS)
        ( "p"              . 112)
        ( "page_down"      . ,KEY_NPAGE)
        ( "page_up"        . ,KEY_PPAGE)
        ( "previous"       . ,KEY_PREVIOUS)
        ( "print"          . ,KEY_PRINT)
        ( "q"              . 113)
        ( "r"              . 114)
        ( "redo"           . ,KEY_REDO)
        ( "reference"      . ,KEY_REFERENCE)
        ( "refresh"        . ,KEY_REFRESH)
        ( "replace"        . ,KEY_REPLACE)
        ( "restart"        . ,KEY_RESTART)
        ( "resume"         . ,KEY_RESUME)
        ( "right"          . ,KEY_RIGHT)
        ( "s"              . 115)
        ( "save"           . ,KEY_SAVE)
        ( "scroll_b"       . ,KEY_SR)
        ( "scroll_f"       . ,KEY_SF)
        ( "select"         . ,KEY_SELECT)
        ( "send"           . ,KEY_SEND)
        ( "set_tab"        . ,KEY_STAB)
        ( "space"          . 32)
        ( "suspend"        . ,KEY_SUSPEND)
        ( "t"              . 116)
        ( "tab"            . 9)
        ( "u"              . 117)
        ( "undo"           . ,KEY_UNDO)
        ( "up"             . ,KEY_UP)
        ( "v"              . 118)
        ( "w"              . 119)
        ( "x"              . 120)
        ( "y"              . 121)
        ( "z"              . 122)
        ( "("              . 123)
        ( "|"              . 124)
        ( ")"              . 125)
        ( "~"              . 126))
      test: string=?
      hash: string-hash)))
