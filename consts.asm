; Constants

; Booleans for flags
NO  = 0
YES = 1

; Hardware specific
FPS = 50
MODE8BASE  = &4800

PAD_RIGHT  = &01
PAD_LEFT   = &02
PAD_DOWN   = &04
PAD_UP     = &08
PAD_START  = &10
PAD_SELECT = &20
PAD_B      = &40
PAD_A      = &80

; Sprites


; Tiles
TILE_CURSOR = &40

; Level specific
SECONDSPERLEVEL = 200

MAP_WIDTH = 32
MAP_HEIGHT = 13

MAP_HERE   = &00
MAP_RIGHT  = &01
MAP_UP     = &02
MAP_LEFT   = &03
MAP_DOWN   = &04

MAP_EMPTY        = 0
MAP_CONCRETE     = 1
MAP_BRICK        = 2
MAP_BOMB         = 3
MAP_HIDDEN_EXIT  = 4
MAP_HIDDEN_BONUS = 5
MAP_BONUS        = 6
MAP_EXIT         = 8

MAX_BOMB = 10
MAX_FIRE = (MAX_BOMB*8)