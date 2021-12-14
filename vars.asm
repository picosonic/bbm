; ---------------------------------------------------------
; After compare, branch if
;
;  reg <  data : BCC
;  reg =  data : BEQ
;  reg >  data : {BEQ elsewhere} BCS
;  reg <= data : BCC BEQ
;  reg >= data : BCS
; ---------------------------------------------------------
; Zero page variables

ORG &0000
GUARD &0090

; Input bitfield
.keys EQUB &00

; Sprite source dest pointers, top and bottom halves
.sprsrc EQUW &0000
.sprsrc2 EQUW &0000

.sprdst EQUW &0000
.sprdst2 EQUW &0000

; Sprite number and x, y block position, and u, v offset (4 px)
;   attributes horiz flip / solid / tile layout
.sprite EQUB &00
.sprx EQUB &00
.spry EQUB &00
.spru EQUB &00
.sprv EQUB &00
.sprflip EQUB &00
.sprsolid EQUB &00
.sprtile EQUB &00
.sprnext EQUB &00

; Number of frames to delay by
.delayframes EQUB &00

.titleptr EQUW &0000

; Title screen cursor state
.cursor EQUB &00

; Top score and current score
.topscore EQUB &00, &00, &00, &00, &00, &00, &00
.score EQUB &00, &00, &00, &00, &00, &00, &00

; Current stage
.stage EQUB &00

; Remaining time for current stage in seconds
.timeleft EQUB &00

; Temporary variables
.tempp EQUB &00
.tempq EQUB &00
.tempr EQUB &00
.temps EQUB &00
.tempt EQUB &00
.tempu EQUB &00
.tempv EQUB &00
.tempw EQUB &00
.tempx EQUB &00
.tempy EQUB &00
.tempz EQUB &00

; Pointer into level array
.stagemapptr EQUW &0000

; Number of frames, wraps around
.framecounter EQUB &00

; Number of frames so far this second
.frames EQUB &00

; Number of lives remaining for current stage
.lifeleft EQUB &00

; Boolean for when on title screen
.inmenu EQUB &00

; Bonuses
.BONUS_POWER        EQUB &00
.BONUS_BOMBS        EQUB &00
.BONUS_SPEED        EQUB &00
.BONUS_NOCLIP       EQUB &00
.BONUS_REMOTE       EQUB &00
.BONUS_BOMBWALK     EQUB &00
.BONUS_FIRESUIT     EQUB &00

; Bonus item validation
.bricks_destroyed   EQUB &00
.chain_reactions    EQUB &00
.exit_bombed        EQUB &00

; Debug mode boolean (show powerups and exit)
.DEBUG              EQUB &00

; Pointer
.sound_ptr EQUW &0000

; Progress through each channel of current melody
.sound_cnt EQUB &00, &00, &00

; Sound sustain per channel
.sound_pause_point EQUB &00, &00, &00
.sound_pause_counter EQUB &00, &00, &00

.zpend

; ---------------------------------------------------------
; Variables in LANGUAGE workspace, &400 to &7FF

ORG &0400
GUARD &0800

.levelmap
SKIP (MAP_WIDTH*MAP_HEIGHT) ; Reserve bytes for in-game level data

; Bomb vars (up to 10 bombs)
.BOMB_ACTIVE         EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_X              EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_Y              EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_TIME_LEFT      EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_TIME_ELAPSED   EQUW &0000, &0000, &0000, &0000, &0000
.BOMB_FRAME          EQUW &0000, &0000, &0000, &0000, &0000

; Bomberman X and Y position in level array, with U and Y offsets (plus cache)
.BOMBMAN_X           EQUB &00, &00
.BOMBMAN_U           EQUB &00, &00
.BOMBMAN_Y           EQUB &00, &00
.BOMBMAN_V           EQUB &00, &00
.BOMBMAN_FRAME       EQUB &00, &00
.BOMBMAN_FLIP        EQUB &00, &00

; First frame of current animation set
.BOMBMAN_FRAMESTART  EQUB &00

; Seed for random number generator
.seed EQUW &0000, &0000

.password_buffer
SKIP 21

; Fire vars (up to 80 fire squares)
.FIRE_ACTIVE
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
.FIRE_X
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
.FIRE_Y
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
.FIRE_EXTRA
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
.FIRE_EXTRA2
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000
  EQUW &0000, &0000, &0000, &0000, &0000

.end_of_vars

; ---------------------------------------------------------
; Variables in printer buffer workspace, &880 to &8BF

ORG &880
GUARD &08C0
