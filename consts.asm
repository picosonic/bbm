; Constants

; Hardware specific
MODE8BASE  = &4800
FPS = 50

MAIN_LOAD_ADDR = &1900
MAIN_RELOC_ADDR = &0E00
MAX_OBJ_SIZE = MODE8BASE-MAIN_RELOC_ADDR
DOWNLOADER_ADDR = MAIN_LOAD_ADDR+MAX_OBJ_SIZE

; Sideways RAM bank for data
SWR_PAGEDATA = &100

MACRO PAGE_SWRDATA
  SEI:LDA SWR_PAGEDATA:STA ROMSEL:CLI
ENDMACRO

MACRO PAGE_RESTORE
  SEI:LDA ROMSEL_CACHE:STA ROMSEL:CLI
ENDMACRO

; Booleans for flags
NO  = 0
YES = 1

PAD_RIGHT  = &01
PAD_LEFT   = &02
PAD_DOWN   = &04
PAD_UP     = &08
PAD_START  = &10
PAD_SELECT = &20
PAD_B      = &40
PAD_A      = &80

; Sprites
SPR_SIZE = 16
SPR_HALFSIZE = SPR_SIZE/2

SPR_EMPTY    = 24
SPR_CONCRETE = 25
SPR_BRICK    = 26
SPR_BRICK2   = 27
SPR_BRICK3   = 28
SPR_BRICK4   = 29
SPR_BRICK5   = 30
SPR_BRICK6   = 31
SPR_BOMB     = 32
SPR_BOMB2    = 33
SPR_BOMB3    = 34
SPR_EXPLODE  = 35
SPR_EXPLODE2 = 36
SPR_EXPLODE3 = 37
SPR_EXPLODE4 = 38

; Tiles (8x8)
TILE_CURSOR = &40

; Tiles (16x16)

; Level specific
SECONDSPERLEVEL = 200
LIVESPERLEVEL = 3

MAP_WIDTH = 15
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

MAX_PW_CHARS = 20
