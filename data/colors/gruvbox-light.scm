;; gruvbox light colorscheme
;; See https://github.com/morhertz/gruvbox

(let* ((palette '((red     124 #xcc241d) (*red     88 #x9d0006)
                  (green   106 #x98971a) (*green  100 #x79740e)
                  (yellow  172 #xd79921) (*yellow 136 #xb57614)
                  (blue     66 #x458588) (*blue    24 #x076678)
                  (purple  132 #xb16286) (*purple  96 #x8f3f71)
                  (aqua     72 #x689d6a) (*aqua    66 #x427b58)
                  (gray    243 #x7c6f64) (*gray   244 #x928374)
                  (bg0_h   230 #xf9f5d7)
                  (bg0     229 #xfbf1c7) (bg0_s   228 #xf2e5bc)
                  (bg1     223 #xebdbb2) (fg4     243 #x7c6f64)
                  (bg2     250 #xd5c4a1) (fg3     241 #x665c54)
                  (bg3     248 #xbdae93) (fg2     239 #x504945)
                  (bg4     246 #xa89984) (fg1     237 #x3c3836)
                                         (fg0     235 #x282828)
                  (orange  166 #xd65d0e) (*orange 130 #xaf3a03)))
       (? (lambda (name) (cadr (assoc name palette)))))
  (if (can-set-color?)
    (for-each (lambda (color)
                (set-color (cadr color) (caddr color)))
              palette))
  (set-option 'color-cmdline     `(default ,(? 'bg0)   ,(? 'fg1)))
  (set-option 'color-error       `(default ,(? 'bg0)   ,(? '*red)))
  (set-option 'color-info        `(default ,(? 'bg0)   ,(? '*yellow)))
  (set-option 'color-statusline  `(default ,(? 'bg1)   ,(? '*aqua)))
  (set-option 'color-titleline   `(default ,(? 'bg0_s) ,(? '*green)))
  (set-option 'color-win         `(default ,(? 'bg0)   ,(? 'fg1)))
  (set-option 'color-win-cur     `(default ,(? 'bg0)   ,(? '*purple)))
  (set-option 'color-win-cur-sel `(default ,(? 'bg1)   ,(? '*purple)))
  (set-option 'color-win-marked  `(default ,(? 'gray)  ,(? 'bg0)))
  (set-option 'color-win-sel     `(default ,(? 'bg1)   ,(? 'fg0)))
  (set-option 'color-win-title   `(default ,(? 'fg4)   ,(? 'bg0))))