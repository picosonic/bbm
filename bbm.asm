INCLUDE "os.asm"
INCLUDE "inkey.asm"

INCLUDE "vars.asm"

ORG &1100
GUARD ROMSBASE

MODE8BASE  = &4800

.start
  ; TODO move any data which overlaps start screen memory

  ; Make sure we are not in decimal mode
  CLD

  ; Mode 1 (320x256 4 colours)
  LDA #&16:JSR OSWRCH
  LDA #&01:JSR OSWRCH

  ; Hide the cursor
  LDA #&17:JSR OSWRCH
  LDA #&01:JSR OSWRCH
  LDA #&00:JSR OSWRCH
  JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH

  ; Hide the cursor (another way)
  LDA #&0A:STA CRTC00
  LDA #&20:STA CRTC01

  ; Set displayed chars per horizontal line to match NES (256 pixels)
  LDA #&01:STA CRTC00
  LDA #&40:STA CRTC01

  ; Shift display horizontally to centre
  LDA #&02:STA CRTC00
  LDA #&59:STA CRTC01

  ; Set displayed chars per column to match NES (240 pixels, with 224 displayed)
  LDA #&06:STA CRTC00
  LDA #&1C:STA CRTC01

  ; Shift display vertically to centre
  LDA #&07:STA CRTC00
  LDA #33:STA CRTC01

  ; Change screen start to &4800 to gain an extra 6k bytes
  LDA #&0D:STA CRTC00
  LDA #&00:STA CRTC01
  LDA #&0C:STA CRTC00
  LDA #(MODE8BASE) DIV 256
  LSR A:LSR A:LSR A
  STA CRTC01

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
  JSR cls

  JSR waitvsync
  JSR drawtitle

.awaitkeys
  JSR rand

  ; check for keypress
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BNE playgame
  LDA #INKEY_SPACE:JSR scankey ; Scan for SPACEBAR
  BEQ awaitkeys

  ; toggle cursor
  JSR waitvsync
  LDA #&3A:JSR drawcursor ; Draw a blank on current position
  LDA cursor
  EOR #&01
  STA cursor
  JSR waitvsync
  LDA #&40:JSR drawcursor ; Draw cursor at new position

  LDA #INKEY_SPACE:JSR unpressed ; Wait for SPACEBAR to be released

  JMP awaitkeys

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

  JSR cls

  ; Draw TIME/SCORE/LIVES
  JSR showstatus
  JSR drawtime
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
  LDA #1:STA sprx
  LDA #2:STA spry
  LDA #0:STA sprite
  JSR drawsprite

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
  ; TODO draw bomberman
  ; TODO THINK
  JSR bombanim ; animate bombs
  JSR stagetimer ; tick game stage timer

  ; check for keypress
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ gameloop

  ; TODO
  JMP gamestart
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
  AND #&3F
  BNE done

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

.titlepal
{
  LDY #&00
.loop
  LDA #&13:JSR OSWRCH
  LDA thispal, Y:JSR OSWRCH:INY
  LDA thispal, Y:JSR OSWRCH:INY
  LDA #&00:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH
  CPY #&08
  BNE loop

  RTS

.thispal
  ; black, red, white, yellow
  EQUB 0,0, 1,1, 2,7, 3,3
}

.gamepal
{
  LDY #&00
.loop
  LDA #&13:JSR OSWRCH
  LDA thispal, Y:JSR OSWRCH:INY
  LDA thispal, Y:JSR OSWRCH:INY
  LDA #&00:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH
  CPY #&08
  BNE loop

  RTS

.thispal
  ; black, blue, red, white
  EQUB 0,0, 1,4, 2,1, 3,7

  RTS
}

.drawtitle
{
  JSR titlepal

  ; Store a pointer to title data
  LDA #(titles) MOD 256:STA titleptr
  LDA #(titles) DIV 256:STA titleptr+1

  ; Set tile cursor
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  LDY #&00

.loop
  ; Load next tile
  LDA (titleptr), Y:STA sprite
  JSR writetile
  INY

  BNE nexttile
  INC titleptr+1
.nexttile
  LDA #(titles+&200) DIV 256
  CMP titleptr+1
  BNE loop

  JSR drawtitletext

  JSR drawtopscore

  LDA #&40:JSR drawcursor

  RTS
}

.drawcursor
{
  PHA

  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  LDX cursor
  LDA cursorl, X
  CLC:ADC sprdst:STA sprdst

  LDX cursor
  LDA cursorh, X
  CLC:ADC sprdst+1:STA sprdst+1

  PLA:STA sprite:JSR writetile

  RTS

; cursor position lookup
.cursorl
  EQUB &80, &00
.cursorh
  EQUB &22, &23
}

.drawtopscore
{
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  LDA #&E0
  CLC:ADC sprdst:STA sprdst
  LDA #&26
  CLC:ADC sprdst+1:STA sprdst+1

  LDX #&00
.nodigits
  LDA topscore, X
  BNE decimals
  LDA #&3A:STA sprite:JSR writetile
  INX
  CPX #&07
  BNE nodigits
  BEQ digitend

.decimals
  LDA topscore, X
  CLC:ADC #&30
  STA sprite:JSR writetile
  INX
  CPX #&07
  BNE decimals

.digitend
  LDA #&30:STA sprite:JSR writetile
  LDA #&30:STA sprite:JSR writetile

  RTS
}

.drawtitletext
{
  LDY #&00 \ Position within current string
  LDX #&06 \ Num. strings to write

.nextstring
  ; Reset tile cursor
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  JSR nextchar
  CLC:ADC sprdst:STA sprdst
  JSR nextchar
  CLC:ADC sprdst+1:STA sprdst+1

.continuedraw
  JSR nextchar
  CMP #&FF
  BEQ breakdraw
  STA sprite:JSR writetile
  BNE continuedraw

.breakdraw
  DEX
  BNE nextstring
  RTS

.nextchar
  LDA menutext, Y
  INY
  RTS

.menutext
  EQUB &90, &22
  EQUS "START", &B0, &B0, &B0, "CONTINUE"
  EQUB &FF

  EQUB &A0, &26
  EQUS "TOP"
  EQUB &FF

  EQUB &30, &2A
  EQUS "TM", &B0, "AND", &B0, &FE, &B0, "1987", &B0, "HUDSON", &B0, "SOFT"
  EQUB &FF

  EQUB &A0, &2E
  EQUS "LICENSED", &B0, "BY"
  EQUB &FF

  EQUB &40, &32
  EQUS "NINTENDO", &B0, "OF", &B0, "AMERICA", &B0, "INC", &FD
  EQUB &FF

  EQUB &00, &36
  EQUS "BBC", &B0, "MICRO", &B0, "PORT", &B0, "2020", &B0, "BY", &B0, "PICOSONIC"
  EQUB &FF
}

.drawstagescreen
{
  JSR cls

  JSR gamepal

  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Set text coordinates
  LDA #&A0
  CLC:ADC sprdst:STA sprdst
  LDA #&1A
  CLC:ADC sprdst+1:STA sprdst+1

  LDX #&04
.nextchar
  LDA stagestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Advance two tile positions
  LDA sprdst:CLC:ADC #&20:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage

  ; Print current stage number
  LDA stage:JSR putnumber

  RTS

.stagestring
  EQUS "EGATS"
}

; Print 2 digit number in A reg, with leading spaces
.putnumber
{
  LDY #'0'
  SEC

.tens
  SBC #10
  BCC donetens
  INY
  BNE tens

.donetens
  ADC #':'
  CPY #'0'
  BNE putnum2
  LDY #':'

.putnum2
  PHA
  STY sprite:JSR writetile
  PLA
  STA sprite:JSR writetile

  RTS
}

.cls
{
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  LDY #&00
.loop
  LDA #&00
  STA (sprdst), Y
  INY
  BNE loop
  INC sprdst+1
  LDA sprdst+1
  CMP #&80
  BNE loop

  RTS
}

.writetile
{
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Store a pointer to spritesheet
  LDA #(tilesheet) MOD 256:STA sprsrc
  LDA #(tilesheet) DIV 256:STA sprsrc+1

  ; Calculate pointer to requested sprite within spritesheet
  LDA sprite
  BEQ calcdone
  TAX
  LDA #&00
.calc
  CLC:ADC #&10
  BCC norm
  INC sprsrc+1
.norm
  DEX
  BNE calc
  STA sprsrc
.calcdone

  ; Draw tile
  LDY #&00
.loop

  LDA sprite

  ; Is sprite => &5A
  CMP #&5A
  BCS nochange

  LDA (sprsrc), Y

  ; Switch white to black
  PHA

  AND #&88
  CMP #&80
  BNE no_one
  PLA
  AND #&77:PHA
.no_one
  PLA:PHA

  AND #&44
  CMP #&40
  BNE no_two
  PLA
  AND #&BB:PHA
.no_two
  PLA:PHA

  AND #&22
  CMP #&20
  BNE no_three
  PLA
  AND #&DD:PHA
.no_three
  PLA:PHA

  AND #&11
  CMP #&10
  BNE no_four
  PLA
  AND #&EE:PHA
.no_four
  PLA

  JMP changedone
.nochange
  LDA (sprsrc), Y
.changedone
  STA (sprdst), Y

  INY
  TYA
  CMP #&10
  BNE loop

  ; Advance to next tile position
  LDA sprdst:CLC:ADC #&10:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage

  PLA
  TAY
  PLA
  TAX
  PLA

  RTS
}

.drawtile
{
  ; Store a pointer to spritesheet
  LDA #(tilesheet) MOD 256:STA sprsrc
  LDA #(tilesheet) DIV 256:STA sprsrc+1

  ; Store a pointer to the screen
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Calculate pointer to requested sprite within spritesheet
  LDA sprite
  BEQ calcdone
  TAX
  LDA #&00
.calc
  CLC:ADC #&10
  BCC norm
  INC sprsrc+1
.norm
  DEX
  BNE calc
  STA sprsrc
.calcdone

  ; Calculate pointer to x,y position of sprite within screen RAM - TODO FIX
  LDA sprdst+1:CLC:ADC spry:STA sprdst+1
  LDA sprdst:CLC:ADC sprx:STA sprdst

  ; Now draw it
  LDY #&00
.loop
  LDA (sprsrc), Y
  STA (sprdst), Y

  INY
  CPY #&10
  BNE loop

  RTS
}

.drawbigtile
{
  TXA
  PHA
  TYA
  PHA

  ; Store a pointer to tilesheet top half
  LDA #(tilesheet) MOD 256:STA sprsrc
  LDA #(tilesheet) DIV 256:STA sprsrc+1

  ; Store a pointer to tilesheet bottom half
  LDA #(tilesheet+&20) MOD 256:STA sprsrc2
  LDA #(tilesheet+&20) DIV 256:STA sprsrc2+1

  ; Store a pointer to the screen
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Calculate pointer to requested sprite within spritesheet
  LDA sprite
  BEQ calcdone
  TAX
  LDA sprsrc
.calc
  CLC
  ADC #&40
  BCC norm
  INC sprsrc+1
.norm
  DEX
  BNE calc
  STA sprsrc

  LDA sprite
  BEQ calcdone
  TAX
  LDA sprsrc2
.calc2
  CLC
  ADC #&40
  BCC norm2
  INC sprsrc2+1
.norm2
  DEX
  BNE calc2
  STA sprsrc2

.calcdone

  JMP raster
}

.drawsprite
{
  TXA
  PHA
  TYA
  PHA

  ; Store a pointer to spritesheet
  LDA #(spritesheet) MOD 256:STA sprsrc
  LDA #(spritesheet) DIV 256:STA sprsrc+1

  LDA #(spritesheet+&100) MOD 256:STA sprsrc2
  LDA #(spritesheet+&100) DIV 256:STA sprsrc2+1

  ; Store a pointer to the screen
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  LDA #(MODE8BASE+&200) MOD 256:STA sprdst2
  LDA #(MODE8BASE+&200) MOD 256:STA sprdst2+1

  ; Calculate pointer to requested sprite within spritesheet
  LDA sprite
  BEQ calcdone
  TAX
  LDA #&00
.calc
  CLC
  ADC #&20
  BCC norm
  INC sprsrc+1:INC sprsrc2+1
  INC sprsrc+1:INC sprsrc2+1
.norm
  DEX
  BNE calc
  STA sprsrc
  STA sprsrc2
.calcdone
}

.raster
{
  ; Calculate pointer to x,y position of sprite/tile within screen RAM
  LDA spry
  BEQ noy
  ASL A:ASL A ; Multiply Y by 4
  STA yjump+2 ; Store result as operand for ADC below
  LDA sprdst+1
.yjump
  CLC:ADC #&00
  STA sprdst+1
.noy

  LDX sprx
  BEQ nox
.xloop
  LDA sprdst:CLC:ADC #&20:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage
  DEX
  BNE xloop

.nox

  ; Calculate bottom part as being + 0x200 from top
  LDA sprdst:STA sprdst2
  LDA sprdst+1:CLC:ADC #&02:STA sprdst2+1

  ; Now draw it
  LDY #&00
.loop
  ; Top half
  LDA (sprsrc), Y
  STA (sprdst), Y

  ; Bottom half
  LDA (sprsrc2), Y
  STA (sprdst2), Y

  INY
  CPY #&20
  BNE loop

  PLA
  TAY
  PLA
  TAX

  RTS
}

; Wait for vertical trace
.waitvsync
{
  LDA #&13
  JSR OSBYTE
  RTS
}

; Delay specified number of frames
.delay
{
  LDA #&13:JSR OSBYTE ; Wait for vsync

  DEC delayframes
  BNE delay
  RTS
}

; Return &FF in A if key is pressed
.scankey
{
  TAX ; Negative INKEY value to check for
  LDY #&FF ; Keyboard scan
  LDA #&81
  JSR OSBYTE
  TYA
  RTS
}

; Wait until specified key is not pressed
.unpressed
{
  PHA
  JSR scankey
  BEQ cleared
  PLA
  JMP unpressed

.cleared
  PLA
  RTS
}

INCLUDE "rand.asm"

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

