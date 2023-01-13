; Data to be loaded to sideways RAM

.swrtitles
INCBIN "TITLE.beeb"

.swrtilesheet
INCBIN "TILES.beeb"

.swrspritesheet
INCBIN "SPRITES.beeb"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Title
.melody_01_c1
INCBIN "melodies/M01C1.bin"
.melody_01_c2
INCBIN "melodies/M01C2.bin"
.melody_01_c3
INCBIN "melodies/M01C3.bin"

; Stage screen
.melody_02_c1
INCBIN "melodies/M02C1.bin"
.melody_02_c2
INCBIN "melodies/M02C2.bin"
.melody_02_c3
INCBIN "melodies/M02C3.bin"

; Stage
.melody_03_c3
INCBIN "melodies/M03C3.bin"

; Stage 2
.melody_04_c1
INCBIN "melodies/M04C1.bin"
.melody_04_c2
INCBIN "melodies/M04C2.bin"
.melody_04_c3
INCBIN "melodies/M04C3.bin"

; God mode
.melody_05_c1
INCBIN "melodies/M05C1.bin"
.melody_05_c2
INCBIN "melodies/M05C2.bin"
.melody_05_c3
INCBIN "melodies/M05C3.bin"

; Bonus
.melody_06_c1
INCBIN "melodies/M06C1.bin"
.melody_06_c2
INCBIN "melodies/M06C2.bin"
.melody_06_c3
INCBIN "melodies/M06C3.bin"

; Fanfare
.melody_07_c1
INCBIN "melodies/M07C1.bin"
.melody_07_c2
INCBIN "melodies/M07C2.bin"
.melody_07_c3
INCBIN "melodies/M07C3.bin"

; Died
.melody_08_c1
INCBIN "melodies/M08C1.bin"
.melody_08_c2
INCBIN "melodies/M08C2.bin"

; Game over
.melody_09_c1
INCBIN "melodies/M09C1.bin"
.melody_09_c2
INCBIN "melodies/M09C2.bin"
.melody_09_c3
INCBIN "melodies/M09C3.bin"

; Final
.melody_10_c3
INCBIN "melodies/M10C3.bin"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Timeout and gamepad state value pairs for DEMO {TIMEOUT, PAD1_STATE} ...
.demo_keydata
  EQUB &3D,  1,  3,&81,  3,&80,&1B,  4,  6,&84,&1B,  4,  2,  5,&34,  1,  8,&41,&13,  1
  EQUB   1,  0,  6,  1,  1,  0, &F,  1,  1,  0,  3,  1,  1,  0,&11,  1,  6,&81,&1B,  1
  EQUB   3,&81, &E,  1,&1A,  0,&11,  1,  5,&81,&16,  1,  2,  0,  1,  1,&11,  4,&10,  0
  EQUB &10,&40,&10,  0,  2,  4,  1,  0,  1,  4,  1,  0, &E,  4,  1,  0,  2,  4,  1,  0
  EQUB   1,  4,&38,  0,&1A,  4,  3,  0,  4,  2,  1,  0,  4,&80,  9,  0,&16,  2,  2,  0
  EQUB   2,  4,  5,  2,  1,  0,&15,  4,&3A,  0, &A,&40,&17,  0, &D,  4,  2,  0,  6,&80
  EQUB   6,  0,&1D,  8,  1,  0, &C,  1,  2,  0,  9,&40, &A,  0,&28,  2,  1,  0,&20,  2
  EQUB &1E,  4,  2,&84,  5,&80,&5D,  1,  6,  0,&1D,  2,&21,  8,  4,  0,  6,&80,  3,  0
  EQUB &1A,  2,  2,  0, &F,  8,  2,  0,  9,&40,  8,  0,  8,&40,&14,  0, &F,  8,  1,  0
  EQUB  &D,  8,  1,  0,  1,  8,  1,  0,&11,  8,  2,  0,&1E,  1,  6,&81,&15,  1,  5,&81
  EQUB &19,  1,  6,&81,  6,  0,&1C,  4,  6,&84,  1,&81,  1,  1,  3,  0,&1B,  1,  1,  0
  EQUB  &E,  8,  1,&48,  8,&40,&17,  0, &D,  4,  1,&84,  6,&80,  2,  0,&1E,  2,  4,&82
  EQUB   1,&80,  1,  0,&1F,  4,  5,&84,&1E,  4,  4,&84,  2,&80,&1C,  2,  2,  0, &F,  8
  EQUB   1,  0,  9,&40,&11,  0, &F,  4,  1,  5,  1,  0,  4,  1,  9,&81,&14,  1,  6,&81
  EQUB &19,  1,  1,  0, &E,  8,  3,&48,  1,  0,  6,&40,&14,  0,  6,&80,  2,&88,  4,  8
  EQUB   1,  0,  8,  8,  1,  0,  3,  8,  2,&88,  1,  0,  2,&88,  1,  0,&14,  8,  5,&88
  EQUB   4,  8,  2,  0,&1B,  1,  7,&81,&18,  1,  6,&81,&15,  1,  2,  9,&10,  8, &A,&40
  EQUB &1A,  0, &A,  4,  1,  0,  6,  4,  1,  0,&1E,  2,  6,  0,&10,  8,  3,&84,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF,&FF
  EQUB &FF,&FF,&FF,&FF,&FF,&FF