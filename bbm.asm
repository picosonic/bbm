; OS defines
INCLUDE "os.asm"
INCLUDE "inkey.asm"
INCLUDE "internal.asm"

; Variable and constant defines
INCLUDE "consts.asm"
INCLUDE "vars.asm"

ORG MAIN_RELOC_ADDR
GUARD ROMSBASE

.start
.datastart

.titles
INCBIN "TITLE.beeb"

.tilesheet
INCBIN "TILES.beeb"

.spritesheet
INCBIN "SPRITES.beeb"

.dataend

.codestart
  JMP init

; Import modules
INCLUDE "input.asm"
INCLUDE "rand.asm"
INCLUDE "menus.asm"
INCLUDE "gfx.asm"
INCLUDE "sound.asm"

.init
  ; Initialise cursor
  LDA #&00:STA cursor
  STA sprflip

  ; Initialise game state
  LDA #YES:STA inmenu

  JSR init_bomberman

  ; Set up vsync event handler
  LDA #&00:STA framecounter:STA frames
  SEI
  LDA #eventhandler MOD 256:STA EVNTV
  LDA #eventhandler DIV 256:STA EVNTV+1
  CLI
  LDA #&0E:LDX #&04:JSR OSBYTE ; Enable vsync event handler

.gamestart

  LDA #YES:STA inmenu

  JSR waitvsync
  JSR drawtitle

  ; Start playing music
  LDA #&01:STA sound_music

.awaitkeys
  JSR rand

  ; Scan for RETURN
  LDA #INKEY_RETURN:JSR scankey
  BNE startpressed

  ; Scan for SPACEBAR
  LDA #INKEY_SPACE:JSR scankey
  BEQ awaitkeys

  ; toggle cursor
  JSR waitvsync
  LDA #&3A:JSR drawcursor ; Draw a blank on current position
  LDA cursor:EOR #&01:STA cursor
  JSR waitvsync
  LDA #&40:JSR drawcursor ; Draw cursor at new position

  LDA #INKEY_SPACE:JSR unpressed ; Wait for SPACEBAR to be released

  JMP awaitkeys

.init_bomberman
{
  ; Init bomberman sprite
  LDA #1:STA BOMBMAN_X:STA BOMBMAN_X+1
  LDA #2:STA BOMBMAN_Y:STA BOMBMAN_Y+1
  LDA #8:STA BOMBMAN_U:STA BOMBMAN_V:STA BOMBMAN_U+1:STA BOMBMAN_V+1
  LDA #0:STA BOMBMAN_FRAME:STA BOMBMAN_FRAME+1
  LDA #0:STA BOMBMAN_FLIP:STA BOMBMAN_FLIP+1

  RTS
}

.startpressed
{
  LDA cursor
  BEQ playgame

  ; Flip cursor
  LDA cursor:EOR #&01:STA cursor

  ; Password entry screen
  JSR password
  LDA tempz:BNE playgame+4
  JMP gamestart
}

; Handler for VBLANK event
.eventhandler
{
  ; Save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  INC framecounter
  INC frames

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  LDA inmenu:BNE menu

  ;LDA #PAL_DBG:JSR setpal

  JSR drawbomberman ; clear bomberman in old pos

  ; Cache
  LDA BOMBMAN_X:STA BOMBMAN_X+1
  LDA BOMBMAN_Y:STA BOMBMAN_Y+1
  LDA BOMBMAN_U:STA BOMBMAN_U+1
  LDA BOMBMAN_V:STA BOMBMAN_V+1
  LDA BOMBMAN_FRAME:STA BOMBMAN_FRAME+1
  LDA BOMBMAN_FLIP:STA BOMBMAN_FLIP+1

  JSR drawbomberman ; draw bomberman in new pos

  ;LDA #PAL_GAME:JSR setpal
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.menu

  JSR read_input
  JSR sound_eventvhandler

  ; Restore registers
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
}

.playgame
{
  ; Initialise bombs
  LDX #MAX_BOMB-1
  LDA #NO
.clearbombs
  STA BOMB_ACTIVE, X
  DEX
  BPL clearbombs

  STA BONUS_REMOTE

  ; Initialise scores
  LDX #&00
.scoreinit
  STA topscore, X
  STA score, X
  INX
  CPX #&07
  BNE scoreinit

  LDA #&01:STA stage
  JSR drawstagescreen

  ; Play stage screen melody
  LDA #&02:STA sound_music

  ; Wait for tune to finish
  JSR sound_waittune

  ; Generate level map
  JSR buildmap

  ; Set time limit
  LDA #SECONDSPERLEVEL:STA timeleft

  ; Set remaining lives
  LDA #&02:STA lifeleft

  ; Clear the screen
  JSR cls

  ; Start playing music
  LDA #&03:STA sound_music

  ; Draw TIME/SCORE/LIVES
  JSR showstatus
  JSR drawtime
  LDA #&00:STA frames

  ; Draw level
  LDX #&00:LDY #&00
  LDA #0:STA sprx
  LDA #1:STA spry

  LDA #(levelmap) MOD 256:STA stagemapptr
  LDA #(levelmap) DIV 256:STA stagemapptr+1

.loop
  LDA (stagemapptr), Y:CLC:ADC #24:STA sprite

  INC stagemapptr
  BNE samepage
  INC stagemapptr+1
.samepage

  JSR drawbigtile

  INC sprx

  INX
  CPX #MAP_WIDTH/2
  BNE loop

  ; Move down a row
  INC spry
  LDX #0:STX sprx
  LDA stagemapptr:CLC:ADC #((MAP_WIDTH/2)-1):STA stagemapptr

  INY
  CPY #MAP_HEIGHT
  BNE loop

  ; Draw bomberman
  JSR init_bomberman
  JSR drawbomberman

  LDA #NO:STA inmenu
}

.gameloop
{
  ; Check if game is paused
  JSR paused
  ; TODO JSR SPRD

  JSR process_inputs ; Check button presses
  JSR waitvsync

  JSR bombtick ; bomb timer operations
  ; TODO THINK
  JSR bombanim ; animate bombs
  JSR stagetimer ; tick game stage timer

  ; check for keypress
  LDA #INKEY_ESCAPE:JSR scankey ; Scan for ESCAPE
  BEQ gameloop

  ; acknowledge ESC
  LDA #&7E:JSR OSBYTE

  ; Stop sprites being drawn (by vsync)
  LDA #YES:STA inmenu

  JSR drawgameoverscreen

  LDA #&09:STA sound_music

  ; wait for RETURN before clearing resume code
.endwait
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ endwait

  ; Stop end music playing (if it still is)
  LDA #NO:STA sound_music

  ; TODO
  JMP gamestart
}

.paused
{
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ not_paused
  LDA #YES:STA sound_disable
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed

.wait_start
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ wait_start
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed
  LDA #NO:STA sound_disable

  ; Reset frame counter
  LDA #&00:STA frames

.not_paused
  RTS
}

.process_inputs
{
  LDX keys
  BEQ done

.case_right
  TXA:AND #PAD_RIGHT
  BEQ case_left
  JSR move_right

.case_left
  TXA:AND #PAD_LEFT
  BEQ case_up
  JSR move_left

.case_up
  TXA:AND #PAD_UP
  BEQ case_down
  JSR move_up

.case_down
  TXA:AND #PAD_DOWN
  BEQ case_action
  JSR move_down

.case_action
  TXA:AND #PAD_A
  BNE drop_bomb

  ; Check we have detonator
  LDA BONUS_REMOTE
  BEQ done

  TXA:AND #PAD_B
  BEQ done
  JSR detonate

.done
  RTS
}

.drop_bomb
{
  ; See if map is empty here
  LDY BOMBMAN_Y:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:JSR checkmap:BNE done

  ; Centre bomberman
  JSR adjust_bombman_hpos
  JSR adjust_bombman_vpos

  ; Find non-active bomb slot
  LDX BONUS_BOMBS
.loop
  LDA BOMB_ACTIVE, X
  BEQ place_bomb
  DEX
  BPL loop

.done
  RTS
}

.place_bomb
{
  ; Place bomb onto map
  LDA #MAP_BOMB:STA (stagemapptr), Y

  ; Record where we placed it
  LDA BOMBMAN_X:STA BOMB_X, X
  LDA BOMBMAN_Y:STA BOMB_Y, X

  ; Start bomb timer
  LDA #&00:STA BOMB_TIME_ELAPSED, X
  LDA #160:STA BOMB_TIME_LEFT, X

  ; Mark bomb slot as active
  LDA #YES:STA BOMB_ACTIVE, X

  ; TODO - play sound effect 3

  ; Draw bomb
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry
  LDA #33:STA BOMB_FRAME, X:STA sprite
  JSR drawbigtile

  RTS
}

.move_down
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #&08
  BCS nextcell
  INC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:INY:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:JSR checkmap:BNE done

  JSR adjust_bombman_hpos
  INC BOMBMAN_V
  LDA BOMBMAN_V
  CMP #&10
  BNE done

  ; Move down to start of next cell
  LDA #&00
  STA BOMBMAN_V
  INC BOMBMAN_Y

.done
  ; Set animation frame (4..7)
  LDA #&04:LDY #&07:JSR setframe

  RTS
}

.move_up
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #&09
  BCC nextcell
  DEC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:DEY:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:JSR checkmap:BNE done

  JSR adjust_bombman_hpos
  DEC BOMBMAN_V
  BPL done

  ; Move down to start of next cell
  LDA #&0F
  STA BOMBMAN_V
  DEC BOMBMAN_Y

.done
  ; Set animation frame (8..11)
  LDA #&08:LDY #&0B:JSR setframe

  RTS
}

.move_left
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #&09
  BCC nextcell
  DEC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:DEY:JSR checkmap:BNE done

  JSR adjust_bombman_vpos
  DEC BOMBMAN_U
  BPL done

  ; Move to start of next cell
  LDA #&0F
  STA BOMBMAN_U
  DEC BOMBMAN_X

.done
  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

  RTS
}

.move_right
{
  ; Flip sprite horizontally
  LDA #YES:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #&08
  BCS nextcell
  INC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:INY:JSR checkmap:BNE done

  JSR adjust_bombman_vpos
  INC BOMBMAN_U
  LDA BOMBMAN_U
  CMP #&10
  BNE done

  ; Move to start of next cell
  LDA #&00
  STA BOMBMAN_U
  INC BOMBMAN_X

.done
  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

  RTS
}

.adjust_bombman_hpos
{
  LDA BOMBMAN_U
  CMP #&08
  BCC adjust_right ; < 8
  BEQ done         ; = 8
  DEC BOMBMAN_U
.done
  RTS

.adjust_right
  INC BOMBMAN_U
  RTS
}

.adjust_bombman_vpos
{
  LDA BOMBMAN_V
  CMP #&08
  BCC adjust_down ; < 8
  BEQ done        ; = 8
  DEC BOMBMAN_V
.done
  RTS

.adjust_down
  INC BOMBMAN_V
  RTS
}

.setframe
{
  ; Is this the same set of animation frames?
  CMP BOMBMAN_FRAMESTART
  BEQ same

  ; Update the new animation frame set
  STA BOMBMAN_FRAME
  STA BOMBMAN_FRAMESTART

.same
  ; Limit animation updates to every 4th frame
  PHA:LDA framecounter:AND #&03:CMP #&02:BEQ anim:PLA:RTS

.anim
  PLA

  ; Move on to the next frame of this set
  INC BOMBMAN_FRAME
  ; Is this frame now out of range?
  CPY BOMBMAN_FRAME
  BCS done

  ; Reset to first frame of set
  STA BOMBMAN_FRAME

.done
  RTS
}

.detonate
{
  RTS
}

.checkmap
{
  LDA (stagemapptr), Y
  BEQ done ; empty

  CMP #MAP_EXIT:BEQ done ; exit
  CMP #MAP_BONUS:BEQ done ; bonus

  CMP #MAP_BRICK:BEQ has_noclip ; brick
  CMP #MAP_HIDDEN_EXIT:BEQ has_noclip ; hidden exit
  CMP #MAP_HIDDEN_BONUS:BEQ has_noclip ; hidden bonus

  CMP #MAP_BOMB:BEQ has_bombwalk ; bomb

.done
  RTS
}

.has_noclip
{
  LDA BONUS_NOCLIP
  EOR #&01

  RTS
}

.has_bombwalk
{
  LDA BONUS_BOMBWALK
  EOR #&01

  RTS
}

.drawbomberman
{
  LDA BOMBMAN_X+1:STA sprx:DEC sprx
  LDA BOMBMAN_Y+1:STA spry

  LDA BOMBMAN_U+1:CLC:ADC #&08:STA spru
  LDA BOMBMAN_V+1:CLC:ADC #&08:STA sprv

  LDX BOMBMAN_FRAME+1:LDA BOMBER_ANIM, X:STA sprite

  LDA BOMBMAN_FLIP+1:STA sprflip
  JSR drawsprite

  ; Reset sprite properties
  LDA #&00:STA spru:STA sprv:STA sprflip
}

.bombtick
{
  LDX #MAX_BOMB-1

.loop
  ; Skip this bomb if it's not active
  LDA BOMB_ACTIVE, X
  BEQ nextbomb

  ; See what's on the map where this bomb is
  LDY BOMB_Y, X
  LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1

  LDY BOMB_X, X
  LDA (stagemapptr), Y

  ; Check if it's a bomb
  CMP #MAP_BOMB
  BNE bombend

  ; Advance animation frame
  INC BOMB_TIME_ELAPSED, X

  ; Check for remote detonator (don't tick)
  LDA BONUS_REMOTE
  BNE nextbomb

  ; Reduce bomb fuse time remaining, then skip if time hasn't run out
  LDA framecounter:AND #&01:BNE nextbomb
  DEC BOMB_TIME_LEFT, X
  BNE nextbomb

  ; LDA #0

.bombend
 ; AND #7
 ; JSR sub_C9B6
 ; LDA byte_A5
 ; CMP #$FF
 ; BEQ explode
 ; INC byte_A5

.explode
  JSR sound_explosion

  ; Remove from map
  LDA #MAP_EMPTY:STA (stagemapptr), Y

  ; Set as inactive
  STA BOMB_ACTIVE, X

  ; Clear bomb sprite
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry
  LDA BOMB_FRAME, X:STA sprite
  JSR drawbigtile

.nextbomb
  DEX
  BPL loop

  RTS
}

; Animate frame for each active bomb
.bombanim
{
  LDX #MAX_BOMB-1

.loop
  ; Skip this bomb if it's not active
  LDA BOMB_ACTIVE, X
  BEQ nextbomb

  ; Skip this bomb if elapsed%16 not 0
  LDA BOMB_TIME_ELAPSED, X
  AND #&0F
  BNE nextbomb

  ; Cache X, Y position for this bomb
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry

  ; Concentrate on bits 0111 0000
  LDA BOMB_TIME_ELAPSED, X
  LSR A:LSR A:LSR A:LSR A
  AND #&03
  TAY
  ; Select bomb frame from lookup
  LDA BOMB_FRAME, X:STA sprite:JSR drawbigtile
  LDA bombframes, Y:STA BOMB_FRAME, X:STA sprite:JSR drawbigtile

.nextbomb
  DEX
  BPL loop

  RTS

.bombframes
  EQUB 33, 34, 33, 32
}

; Reduce time left by a second
.stagetimer
{
  LDA frames
  CMP #FPS
  BCC done

  ; Reset frame counter for this second
  LDA #&00:STA frames

; Here temporarily
  JSR drawtime
;  LDA #FPS:STA delayframes:JSR delay

  LDA timeleft
  CMP #255
  BEQ done
  DEC timeleft
  BNE done

  ; TODO remove all monsters
  ; TODO add a bunch of small monsters
  ; TODO respawn bonus

.done
  RTS
}

.drawtime
{
  ; Set text coordinates
  LDX #&05:LDY #&00:JSR positiontextcursor

  LDA timeleft
  CMP #255
  BNE someleft
  LDA #0
.someleft

  LDY #'0'
  SEC

.l1
  SBC #100
  BCC l2
  INY
  BNE l1

.l2
  ADC #&64
  CPY #'0'
  BNE l3
  LDY #':'
  STY sprite:JSR writetile

  JMP putnumber

.l3
  STY sprite:JSR writetile
  LDY #'0'
  SEC

.l4
  SBC #10
  BCC l5
  INY
  BNE l4

.l5
  ADC #':'
  STY sprite:JSR writetile
  STA sprite:JSR writetile

  RTS
}

.showstatus
{
  ; Set text coordinates
  LDX #&00:LDY #&00:JSR positiontextcursor

  ; Write "TIME"
  LDX #&03
.nextchar
  LDA timestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Advance text coordinates
  LDA #&C0
  CLC:ADC sprdst:STA sprdst
  LDA #&01
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write trailing zeroes of score
  LDA #'0':STA sprite:JSR writetile:JSR writetile

  ; Advance text coordinates
  LDA #&40
  CLC:ADC sprdst:STA sprdst
  LDA #&00
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write "LEFT"
  LDX #&03
.nextchar2
  LDA lifestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar2

  ; Print lives remaining
  LDA lifeleft:JSR putnumber

  RTS

.timestring
  EQUS "EMIT"
.lifestring
  EQUS "TFEL"
}

.buildmap
{
  JSR addconcreteblocks

  ; Place exit (under brick) randomly on map
  JSR randomcoords
  LDA #MAP_HIDDEN_EXIT:STA (stagemapptr), Y

  ; Place bonus (under brick) randomly on map
  JSR randomcoords
  LDA #MAP_HIDDEN_BONUS:STA (stagemapptr), Y

  ; Place (2*stage) + 50 bricks randomly
  LDA stage:ASL A:CLC:ADC #&32
  STA tempx

.nextbrick
  ; Place brick on map
  JSR randomcoords
  LDA #MAP_BRICK:STA (stagemapptr), Y

  DEC tempx
  BNE nextbrick

  RTS
}

.addconcreteblocks
{
  LDA #(levelmap) MOD 256:STA stagemapptr
  LDA #(levelmap) DIV 256:STA stagemapptr+1

  LDY #0

  LDX #&00:JSR stagerow ; Top wall
  LDX #&20:JSR stagerow ; Blank row
  LDX #&40:JSR stagerow ; Alternate concrete
  LDX #&20:JSR stagerow ; ...
  LDX #&40:JSR stagerow
  LDX #&20:JSR stagerow
  LDX #&40:JSR stagerow
  LDX #&20:JSR stagerow
  LDX #&40:JSR stagerow
  LDX #&20:JSR stagerow
  LDX #&40:JSR stagerow
  LDX #&20:JSR stagerow
  LDX #&00 ; Bottom wall

.stagerow
  LDA #&20:STA tempx

.stagecell
  LDA stagerows, X
  STA (stagemapptr), Y
  INC stagemapptr
  BNE hipart
  INC stagemapptr+1

.hipart
  INX
  DEC tempx
  BNE stagecell

  RTS

.stagerows
  EQUB 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  EQUB 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1
  EQUB 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1
}

; Find an empty position on the 32x13 map
.randomcoords
{
  JSR rand
  ROR A:ROR A ; A = A/4
  AND #&1F ; 0 to 31
  BEQ randomcoords
  STA tempx

.loop
  JSR rand
  ROR A:ROR A:ROR A ; A = A/8
  AND #&0F ; 0 to 15
  BEQ loop
  CMP #&0C ; if A >= 13, try again
  BCS loop
  STA tempy

  TAY

  LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1

  LDY tempx
  LDA (stagemapptr), Y ; Check what's on the map already
  BNE randomcoords ; If not blank, retry
  CPY #&03
  BCS done
  LDA tempy
  CMP #&03
  BCC randomcoords

.done
  RTS
}

; Level data lookup tables
.multtaby
  EQUB 0,&20,&40,&60,&80,&A0,&C0,&E0,  0,&20,&40,&60,&80
.multtabx
  EQUB (levelmap DIV 256), (levelmap DIV 256), (levelmap DIV 256), (levelmap DIV 256), (levelmap DIV 256), (levelmap DIV 256), (levelmap DIV 256)
  EQUB (levelmap DIV 256), (levelmap DIV 256)+1, (levelmap DIV 256)+1, (levelmap DIV 256)+1, (levelmap DIV 256)+1, (levelmap DIV 256)+1

; Delay specified number of frames
.delay
{
  LDA #&13:JSR OSBYTE ; Wait for vsync

  DEC delayframes
  BNE delay
  RTS
}

; Stage 2
.melody_04_c1
;INCBIN "melodies/M04C1.bin"
.melody_04_c2
;INCBIN "melodies/M04C2.bin"
.melody_04_c3
;INCBIN "melodies/M04C3.bin"

; God mode
.melody_05_c1
;INCBIN "melodies/M05C1.bin"
.melody_05_c2
;INCBIN "melodies/M05C2.bin"
.melody_05_c3
;INCBIN "melodies/M05C3.bin"

; Bonus
.melody_06_c1
;INCBIN "melodies/M06C1.bin"
.melody_06_c2
;INCBIN "melodies/M06C2.bin"
.melody_06_c3
;INCBIN "melodies/M06C3.bin"

; Fanfare
.melody_07_c1
;INCBIN "melodies/M07C1.bin"
.melody_07_c2
;INCBIN "melodies/M07C2.bin"
.melody_07_c3
;INCBIN "melodies/M07C3.bin"

; Died
.melody_08_c1
INCBIN "melodies/M08C1.bin"
.melody_08_c2
INCBIN "melodies/M08C2.bin"

; Final
.melody_10_c1
;INCBIN "melodies/M10C1.bin"
.melody_10_c2
;INCBIN "melodies/M10C2.bin"
.melody_10_c3
;INCBIN "melodies/M10C3.bin"

.usedmemory

ORG MAIN_LOAD_ADDR+MAX_OBJ_SIZE-(MAIN_LOAD_ADDR-MAIN_RELOC_ADDR)
.downloader
INCBIN "DOWNLOADER"
.codeend

ORG &0900
GUARD &0D00
.extradata

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

; Game over
.melody_09_c1
INCBIN "melodies/M09C1.bin"
.melody_09_c2
INCBIN "melodies/M09C2.bin"
.melody_09_c3
INCBIN "melodies/M09C3.bin"

INCLUDE "extra.asm"
.extraend

ORG &00
CLEAR &00, &FF
.plingboot
EQUS "*BASIC", &0D ; Reset to BASIC
EQUS "PAGE=&1900", &0D ; Set PAGE
EQUS "*FX21", &0D ; Flush buffer
EQUS "CLOSE#0:CH.", '"', "LOADER", '"', &0D ; Close "!BOOT" and run the main code
EQUS "REM BBM build ", TIME$ ; Add a build date
.plingend

SAVE "!BOOT", plingboot, plingend
PUTBASIC "loader.bas", "$.LOADER"
PUTFILE "loadscr", "$.LOADSCR", MODE2BASE
SAVE "EXTRA", extradata, extraend
SAVE "BBM", start, codeend, DOWNLOADER_ADDR, MAIN_LOAD_ADDR

PRINT "-------------------------------------------"
PRINT "Zero page from &00 to ", ~zpend-1, "  (", ZP_ECONET_WORKSPACE-zpend, " bytes left )"
PRINT "VARS from &400 to ", ~end_of_vars-1, "  (", SOUND_WORKSPACE-end_of_vars, " bytes left )"
PRINT "TUNES/EXTRA from ", ~extradata, " to ", ~extraend-1, "  (", NMI_WORKSPACE-extraend, " bytes left )"
PRINT "SPRITES/TILES from ", ~datastart, " to ", ~dataend-1
PRINT "CODE from ", ~codestart, " to ", ~codeend-1, "  (", codeend-codestart, " bytes )"
PRINT ""
remaining = MODE8BASE-usedmemory
PRINT "Bytes left : ", ~remaining, "  (", remaining, " bytes )"
PRINT "-------------------------------------------"