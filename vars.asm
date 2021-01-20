; ---------------------------------------------------------
; Zero page variables

ORG &0060

; Sprite source dest pointers, top and bottom halves
.sprsrc EQUW &0000
.sprsrc2 EQUW &0000

.sprdst EQUW &0000
.sprdst2 EQUW &0000

; Sprite number and x, y block position, and u, v offset (4 px)
.sprite EQUB &00
.sprx EQUB &00
.spry EQUB &00
.spru EQUB &00
.sprv EQUB &00

; Number of frames to delay by
.delayframes EQUB &00

.titleptr EQUW &0000

; Title screen cursor state
.cursor EQUB &00

; Top score and current score
.topscore EQUW &0000, &0000, &0000
.score EQUW &0000, &0000, &0000

; Current stage
.stage EQUB &00

; Remaining time for current stage in seconds
.timeleft EQUB &00

; Temporary variables
.tempw EQUB &00
.tempx EQUB &00
.tempy EQUB &00
.tempz EQUB &00

; Pointer into level array
.stagemapptr EQUW &0000

; Number of frames, wraps around
.framecounter EQUB &00

; Number of lives remaining for current stage
.lifeleft EQUB &00

; Boolean for when on title screen
.inmenu EQUB &00

; Bonuses
.BONUS_POWER         EQUB &00
.BONUS_BOMBS         EQUB &00
.BONUS_SPEED         EQUB &00
.BONUS_NOCLIP        EQUB &00
.BONUS_REMOTE        EQUB &00
.BONUS_BOMBWALK      EQUB &00
.BONUS_FIRESUIT      EQUB &00

; Debug mode boolean (show powerups and exit)
.DEBUG              EQUB &00

; ---------------------------------------------------------
; Variables in LANGUAGE workspace, &400 to &7FF

ORG &0400

; Bomb vars (up to 10 bombs)
.BOMB_ACTIVE         EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_X              EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_Y              EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_TIME_LEFT      EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_TIME_ELAPSED   EQUW &0000, &0000, &0000, &0000, &0000

; Bomberman X and Y position in level array, with U and Y offsets
.BOMBMAN_X           EQUB &00
.BOMBMAN_U           EQUB &00
.BOMBMAN_Y           EQUB &00
.BOMBMAN_V           EQUB &00
.BOMBMAN_FRAME       EQUB &00

; Seed for random number generator
.seed EQUW &0000, &0000

.password_buffer
SKIP 20

ALIGN &100

.levelmap
SKIP (32*13) ; Reserve bytes for in-game level data
