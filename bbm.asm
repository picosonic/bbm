; OS defines
INCLUDE "os.asm"
INCLUDE "inkey.asm"

; Variable defines
INCLUDE "vars.asm"

ORG &1200
GUARD ROMSBASE

MODE8BASE  = &4800

.start
{
  ; TODO move any data which overlaps start screen memory

  ; Make sure we are not in decimal mode
  CLD

  ; Jump to initialisation
  JMP init
}

; Import modules
INCLUDE "input.asm"
INCLUDE "rand.asm"
INCLUDE "menus.asm"
INCLUDE "gfx.asm"
INCLUDE "sound.asm"

.init
  JSR mode8

  ; Load data files
  LDX #titlestr MOD 256:LDY #titlestr DIV 256:JSR OSCLI
  LDX #tilestr MOD 256:LDY #tilestr DIV 256:JSR OSCLI
  LDX #sprstr MOD 256:LDY #sprstr DIV 256:JSR OSCLI
  LDX #extrastr MOD 256:LDY #extrastr DIV 256:JSR OSCLI
  LDX #tunestr MOD 256:LDY #tunestr DIV 256:JSR OSCLI

  ; Initialise sprite
  LDA #&00:STA sprite

  ; Initialise cursor
  STA cursor

  ; Initialise bombs
  LDX #9
  LDA #0
.clearbombs
  STA BOMB_ACTIVE, X
  DEX
  BPL clearbombs

  ; Initialise scores
  LDX #&00
.scoreinit
  STA topscore, X
  STA score, X
  INX
  CPX #&07
  BNE scoreinit

  ; Initialise game state
  LDA #&01:STA inmenu

  ; Initialise sound
  JSR sound_init

  ; Set up vsync event handler
  LDA #&00:STA framecounter
  SEI
  LDA #eventhandler MOD 256:STA EVNTV
  LDA #eventhandler DIV 256:STA EVNTV+1
  CLI
  LDA #&0E:LDX #&04:JSR OSBYTE ; Enable vsync event handler

.gamestart

  LDA #&01:STA inmenu

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
  LDA #&01:STA stage
  JSR drawstagescreen

  ; Play stage screen melody
  LDA #&02:STA sound_music

  ; Wait for tune to finish
  JSR sound_waittune

  ; Play main game melody
  LDA #&03:STA sound_music

  ; Generate level map
  JSR buildmap

  ; Set time limit
  LDA #200:STA timeleft

  ; Set remaining lives
  LDA #&02:STA lifeleft

  ; Clear the screen
  JSR cls

  ; Start playing music
  LDA #&03:STA sound_music

  ; Draw TIME/SCORE/LIVES
  JSR showstatus
  JSR drawtime
  LDA #&00:STA framecounter
  LDA #&00:STA inmenu

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
  CPX #16
  BNE loop

  ; Move down a row
  INC spry
  LDX #0:STX sprx
  LDA stagemapptr:CLC:ADC #15:STA stagemapptr

  INY
  CPY #13
  BNE loop

  ; Draw bomberman
  LDA #1:STA BOMBMAN_X
  LDA #2:STA BOMBMAN_Y
  LDA #0:STA BOMBMAN_FRAME
  JSR drawbomberman

  ; Place a test bomb
  ;LDX #&00
  ;LDA #&02:STA BOMB_X, X
  ;LDA #&02:STA BOMB_Y, X
  ;LDA #&01:STA BOMB_ACTIVE, X
  ;
  ;LDX #&01
  ;LDA #&01:STA BOMB_X, X
  ;LDA #&03:STA BOMB_Y, X
  ;LDA #&01:STA BOMB_ACTIVE, X
}

.gameloop
{
  ; Check if game is paused
  JSR paused
  ; TODO JSR SPRD
  
  JSR waitvsync
  JSR drawbomberman ; clear bomberman in old pos
  JSR process_inputs ; Check button presses
  JSR drawbomberman ; draw bomberman in new pos

  JSR bombtick ; bomb timer operations
  ; TODO THINK
  JSR bombanim ; animate bombs
  JSR stagetimer ; tick game stage timer

  ; check for keypress
  LDA #INKEY_SPACE:JSR scankey ; Scan for RETURN
  BEQ gameloop

  JSR drawgameoverscreen

  LDA #&09:STA sound_music
  JSR sound_waittune

  ; wait for RETURN before clearing resume code
.endwait
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ endwait

  ; TODO
  JMP gamestart
}

.paused
{
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ not_paused
  LDA #&01:STA sound_disable
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed

.wait_start
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ wait_start
  LDA #&00:STA sound_disable
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed

.not_paused
  RTS
}

.process_inputs
{
  LDA #INKEY_X:JSR scankey ; Scan for "X" (right)
  BEQ case_left
  JSR move_right

.case_left
  LDA #INKEY_Z:JSR scankey ; Scan for "Z" (left)
  BEQ case_up
  JSR move_left

.case_up
  LDA #INKEY_COLON:JSR scankey ; Scan for ":" (up)
  BEQ case_down
  JSR move_up

.case_down
  LDA #INKEY_FWDSLASH:JSR scankey ; Scan for "." (down)
  BEQ case_action
  JSR move_down

.case_action
;  LDA #INKEY_SPACE:JSR scankey ; Scan for "SPACE" (bomb)
;  BNE drop_bomb

;  ; Check we have detonator
;  LDA BONUS_REMOTE
;  BEQ done

;  LDA #INKEY_CLOSESQBRACKET:JSR scankey ; Scan for "[" (detonate)
;  BEQ done
;  JSR detonate

.done
  RTS
}

.drop_bomb
{
  RTS
}

.move_right
{
   ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #&04
  BCS nextcell
  INC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:INY:JSR checkmap:BNE done

  ; Move offset down
  JSR adjust_bombman_vpos
  INC BOMBMAN_U
  LDA BOMBMAN_U
  CMP #&08
  BNE done

  ; Move down to start of next cell
  LDA #&00
  STA BOMBMAN_U
  INC BOMBMAN_X

  ; TODO flip sprite horizontally

  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

.done
  RTS
}

.move_left
{
  ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #&05
  BCC nextcell
  DEC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:DEY:JSR checkmap:BNE done

  ; Move offset left
  JSR adjust_bombman_vpos
  DEC BOMBMAN_U
  BPL done

  ; Move down to start of next cell
  LDA #&07
  STA BOMBMAN_U
  DEC BOMBMAN_X

  ; TODO disable horizontal flip

  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

.done
  RTS
}

.move_up
{
  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #&05
  BCC nextcell
  DEC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:DEY:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:JSR checkmap:BNE done

  ; Move offset up
  JSR adjust_bombman_hpos
  DEC BOMBMAN_V
  BPL done

  ; Move down to start of next cell
  LDA #&07
  STA BOMBMAN_V
  DEC BOMBMAN_Y

  ; Set animation frame (8..11)
  LDA #&08:LDY #&0B:JSR setframe

.done
  RTS
}

.move_down
{
  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #&04
  BCS nextcell
  INC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:INY:LDA multtaby, Y:STA stagemapptr
  LDA multtabx, Y:STA stagemapptr+1
  LDY BOMBMAN_X:JSR checkmap:BNE done

  ; Move offset down
  JSR adjust_bombman_hpos
  INC BOMBMAN_V
  LDA BOMBMAN_V
  CMP #&08
  BNE done

  ; Move down to start of next cell
  LDA #&00
  STA BOMBMAN_V
  INC BOMBMAN_Y

  ; Set animation frame (4..7)
  LDA #&04:LDY #&07:JSR setframe

.done
  RTS
}

.adjust_bombman_hpos
{
  LDA BOMBMAN_U
  CMP #&04
  BCC adjust_right ; < 4
  BEQ done         ; = 4
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
  CMP #&04
  BCC adjust_down ; < 4
  BEQ done        ; = 4
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
  CMP #&08:BEQ done
  CMP #&06:BEQ done

  CMP #&02:BEQ has_noclip
  CMP #&04:BEQ has_noclip ; exit
  CMP #&05:BEQ has_noclip ; bonus
  
  CMP #&03:BEQ has_bombwalk ; bomb
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
  LDA BOMBMAN_X:STA sprx
  LDA BOMBMAN_Y:STA spry
  LDA BOMBMAN_U:STA spru
  LDA BOMBMAN_V:STA sprv

  INC spry ; TEMPORARILY HERE
  LDX BOMBMAN_FRAME:LDA BOMBER_ANIM, X:STA sprite
  JSR drawsprite

  ; Reset sprite offsets
  LDA #&00:STA spru:STA sprv
}

.bombtick
{
  LDX #9

.loop
  ; Skip this bomb if it's not active
  LDA BOMB_ACTIVE, X
  BEQ nextbomb

  ; Advance animation frame
  INC BOMB_TIME_ELAPSED, X

.nextbomb
  DEX
  BPL loop

  RTS
}

; Animate frame for each active bomb
.bombanim
{
  LDX #9

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
  LDA BOMB_Y, X:STA spry

  ; Concentrate on bits 0111 0000
  LDA BOMB_TIME_ELAPSED, X
  LSR A:LSR A:LSR A:LSR A
  AND #&03
  TAY
  ; Select bomb frame from lookup
  LDA bombframes, Y
  STA sprite:JSR drawbigtile

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
  LDA framecounter
  CMP #50
  BNE done
  LDA #&00:STA framecounter

; Here temporarily
  JSR drawtime
;  LDA #50:STA delayframes:JSR delay

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
  LDA #&04:STA (stagemapptr), Y

  ; Place bonus (under brick) randomly on map
  JSR randomcoords
  LDA #&05:STA (stagemapptr), Y

  ; Place 50 + (2*stage) bricks randomly
  LDA #&32
  CLC:ADC stage
  CLC:ADC stage
  STA tempx

.nextbrick
  ; Place brick on map
  JSR randomcoords
  LDA #&02:STA (stagemapptr), Y

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

.titlestr
EQUS "L.TITLE", &0D
.tilestr
EQUS "L.TILES", &0D
.sprstr
EQUS "L.SPRITES", &0D
.tunestr
EQUS "L.TUNES", &0D
.extrastr
EQUS "L.EXTRA", &0D
.end

ALIGN &100

.titles
INCBIN "TITLE.beeb"

.tilesheet
INCBIN "TILES.beeb"

.spritesheet
INCBIN "SPRITES.beeb"

.dataend
  RTS ; Here just to advise on remaining space

ORG &900
.melodies

.melody_01_c1
INCBIN "melodies/M01C1.bin"
.melody_01_c2
INCBIN "melodies/M01C2.bin"
.melody_01_c3
INCBIN "melodies/M01C3.bin"

.melody_02_c1
INCBIN "melodies/M02C1.bin"
.melody_02_c2
INCBIN "melodies/M02C2.bin"
.melody_02_c3
INCBIN "melodies/M02C3.bin"

.melody_03_c3
INCBIN "melodies/M03C3.bin"

.melody_04_c1
INCBIN "melodies/M04C1.bin"
.melody_04_c2
INCBIN "melodies/M04C2.bin"
.melody_04_c3
INCBIN "melodies/M04C3.bin"

.melody_05_c1
INCBIN "melodies/M05C1.bin"
.melody_05_c2
INCBIN "melodies/M05C2.bin"
.melody_05_c3
INCBIN "melodies/M05C3.bin"

.melody_06_c1
INCBIN "melodies/M06C1.bin"
.melody_06_c2
INCBIN "melodies/M06C2.bin"
.melody_06_c3
INCBIN "melodies/M06C3.bin"

.melody_08_c1
INCBIN "melodies/M08C1.bin"
.melody_08_c2
INCBIN "melodies/M08C2.bin"

.melody_09_c1
INCBIN "melodies/M09C1.bin"

  EQUS "JR" ; Padding
  RTI ; At &0D00 to allow use of NMI workspace

.melody_07_c1
INCBIN "melodies/M07C1.bin"
.melody_07_c2
INCBIN "melodies/M07C2.bin"
.melody_07_c3
INCBIN "melodies/M07C3.bin"

.melody_09_c2
INCBIN "melodies/M09C2.bin"
.melody_09_c3
INCBIN "melodies/M09C3.bin"

.melody_10_c1
INCBIN "melodies/M10C1.bin"
.melody_10_c2
INCBIN "melodies/M10C2.bin"
.melody_10_c3
INCBIN "melodies/M10C3.bin"

.extradata
INCLUDE "extra.asm"
.eof RTS

SAVE "BBM", start, end
SAVE "TITLE", titles, tilesheet
SAVE "TILES", tilesheet, spritesheet
SAVE "SPRITES", spritesheet, dataend
SAVE "TUNES", melodies, extradata
SAVE "EXTRA", extradata, eof
