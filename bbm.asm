; OS defines
INCLUDE "os.asm"
INCLUDE "inkey.asm"

; Variable defines
INCLUDE "vars.asm"

ORG &1200
GUARD ROMSBASE

MODE8BASE  = &4800

.start
  ; TODO move any data which overlaps start screen memory

  ; Make sure we are not in decimal mode
  CLD

  ; Jump to initialisation
  JMP init

; Import modules
INCLUDE "input.asm"
INCLUDE "rand.asm"
INCLUDE "menus.asm"
INCLUDE "gfx.asm"
INCLUDE "sound.asm"

.init
  JSR mode8

  ; Load data files
  LDX #(titlestr) MOD 256:LDY #(titlestr) DIV 256:JSR OSCLI
  LDX #(tilestr) MOD 256:LDY #(tilestr) DIV 256:JSR OSCLI
  LDX #(sprstr) MOD 256:LDY #(sprstr) DIV 256:JSR OSCLI

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

  ; Set up vsync event handler
  LDA #&00:STA framecounter
  LDA #(eventhandler) MOD 256:STA EVNTV
  LDA #(eventhandler) DIV 256:STA EVNTV+1
  LDA #&0E:LDX #&04:JSR OSBYTE ; Enable vsync event handler

.gamestart

  LDA #&01:STA inmenu

  JSR waitvsync
  JSR drawtitle

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

  ; Wait 1 second
  LDA #50:STA delayframes:JSR delay

  ; Generate level map
  JSR buildmap

  ; Set time limit
  LDA #200:STA timeleft

  ; Set remaining lives
  LDA #&02:STA lifeleft

  ; Clear the screen
  JSR cls

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
  LDX #&00
  LDA #&02:STA BOMB_X, X
  LDA #&02:STA BOMB_Y, X
  LDA #&01:STA BOMB_ACTIVE, X

  LDX #&01
  LDA #&01:STA BOMB_X, X
  LDA #&03:STA BOMB_Y, X
  LDA #&01:STA BOMB_ACTIVE, X
}

.gameloop
{
  ; TODO Check if game is paused
  ; TODO JSR SPRD
  ; TODO check button presses
  JSR bombtick ; bomb timer operations
  JSR drawbomberman
  ; TODO THINK
  JSR bombanim ; animate bombs
  JSR stagetimer ; tick game stage timer

  ; check for keypress
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ gameloop

  JSR drawgameoverscreen

  ; Wait 1 second
  LDA #50:STA delayframes:JSR delay

  ; TODO
  JMP gamestart
}

.drawbomberman
{
  LDA BOMBMAN_X:STA sprx
  LDA BOMBMAN_Y:STA spry
  LDA BOMBMAN_FRAME:STA sprite
  JSR drawsprite
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
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Set text coordinates
  LDA #&50
  CLC:ADC sprdst:STA sprdst
  LDA #&0
  CLC:ADC sprdst+1:STA sprdst+1

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
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Set text coordinates
  LDA #&0
  CLC:ADC sprdst:STA sprdst
  LDA #&0
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write "TIME"
  LDX #&03
.nextchar
  LDA timestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Set text coordinates
  LDA #&C0
  CLC:ADC sprdst:STA sprdst
  LDA #&01
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write trailing zeroes of score
  LDA #&30:STA sprite:JSR writetile:JSR writetile

  ; Set text coordinates
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

.alldone
  JMP alldone

.anim
  JSR waitvsync

  ; Draw sprite to screen
  JSR drawtile

  LDA sprx:CLC:ADC #&10:STA sprx

  LDA #5:STA delayframes:JSR delay

  INC sprite
  LDA sprite
  ;CMP #&80
  BNE finished
  LDA #&00:STA sprite

.finished
  NOP
  JMP anim
  RTS

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
.end

ALIGN &100

.titles
INCBIN "TITLE.beeb"

.tilesheet
INCBIN "TILES.beeb"

.spritesheet
INCBIN "SPRITES.beeb"

.eof
  RTS ; Here just to advise on remaining space

SAVE "BBM", start, end
SAVE "TITLE", titles, tilesheet
SAVE "TILES", tilesheet, spritesheet
SAVE "SPRITES", spritesheet, eof

