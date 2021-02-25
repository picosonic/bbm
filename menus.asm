.positiontextcursor
{
  ; Save accumulator
  PHA

  ; Postition at start of screen memory
  LDA #(MODE8BASE) MOD 256:STA sprdst
  LDA #(MODE8BASE) DIV 256:STA sprdst+1

  ; Add y offset
  TYA:BEQ doney
.yloop
  INC sprdst+1:INC sprdst+1
  DEY
  BNE yloop
.doney

  ; Add x offset
  TXA:BEQ donex
.xloop
  LDA sprdst:CLC:ADC #&10:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage
  DEX
  BNE xloop
.donex

  ; Restore accumulator
  PLA

  RTS
}

.drawtitle
{
  ; Clear palette whilst drawing
  LDA #PAL_BLANK:JSR setpal
  JSR cls

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

  ; Show graphics
  LDA #PAL_TITLE:JSR setpal

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
  ; Position text cursor to write top score
  LDX #&0E:LDY #&13
  JSR positiontextcursor

  LDX #&00
.nodigits
  LDA topscore, X
  BNE decimals
  LDA #':':STA sprite:JSR writetile
  INX
  CPX #&07
  BNE nodigits
  BEQ digitend

.decimals
  LDA topscore, X
  CLC:ADC #'0'
  STA sprite:JSR writetile
  INX
  CPX #&07
  BNE decimals

.digitend
  LDA #'0':STA sprite:JSR writetile:JSR writetile

  RTS
}

.drawtitletext
{
  LDY #&00 ; Position within current string
  LDX #&06 ; Num. strings to write

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
  EQUS "BBC", &B0, "MICRO", &B0, "PORT", &B0, "2021", &B0, "BY", &B0, "PICOSONIC"
  EQUB &FF
}

.drawstagescreen
{
  JSR cls

  LDA #PAL_GAME:JSR setpal

  ; Position text cursor to write "STAGE n"
  LDX #&0A:LDY #&0D
  JSR positiontextcursor

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

.drawbonusscreen
{
  JSR cls

  LDA #PAL_GAME:JSR setpal

  ; Position text cursor to write "BONUS STAGE"
  LDX #&0A:LDY #&0D
  JSR positiontextcursor

  LDX #&0A
.nextchar
  LDA bonusstring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  RTS

.bonusstring
  EQUS "EGATS:SUNOB"
}

.drawgameoverscreen
{
  JSR cls

  LDA #PAL_GAME:JSR setpal

  ; Position text cursor to write "GAME OVER"
  LDX #&0A:LDY #&0D
  JSR positiontextcursor

  LDX #&08
.nextchar
  LDA gameoverstring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Create a secret code

  ; High nibble of bonus power
  LDA BONUS_POWER
  LSR A:LSR A:LSR A:LSR A
  STA tempu

  ; Low nibble of stage
  LDA stage
  AND #&0F
  STA tempv

  ; High nibble of stage
  LDA stage
  LSR A:LSR A:LSR A:LSR A
  STA tempw

  ; Calculate the first 3 checksums
  LDY #&00
  LDX #&00
  LDA #&03:STA tempz

.loop
  JSR calcsum
  JSR getpassptr
  LDA tempx
  STA (stagemapptr), Y
  DEC tempz
  BNE loop

  ; Calculate final checksum
  JSR calcsum

  ; Add checksum 1 * 2
  LDA tempp
  ASL A
  CLC:ADC tempx
  STA tempx

  ; Add checksum 2 * 2
  LDA tempq
  ASL A
  CLC:ADC tempx
  STA tempx

  ; Add checksum 3 * 2
  LDA tempr
  ASL A
  CLC:ADC tempx
  STA temps

  LDY #&00
  STY seed
  LDX #&00

.loop2
  JSR getpassptr
  LDA (stagemapptr), Y
  AND #&0F
  SEC:SBC seed
  SEC:SBC #&07
  AND #&0F
  STA password_buffer, X
  STA seed
  CPX #20
  BNE loop2

  ; Position text cursor to write secret code
  LDX #&06:LDY #&16
  JSR positiontextcursor

  ; Write the secret code
  LDX #&01
.nextpwchar
  LDA password_buffer, X:TAY
  LDA passwordencode, Y
  STA sprite:JSR writetile
  INX
  CPX #21
  BNE nextpwchar 

  RTS

.gameoverstring
  EQUS "REVO:EMAG"

.passwordencode
  EQUS "AOFKCPGELBHMJDNI"
}

; Calculate a sum of 4 bytes, from X reg offset onwards
.calcsum
{
  LDA #&04:STA tempy
  LDA #&00:STA tempx

.loop
  JSR getpassptr

  LDA (stagemapptr), Y
  CLC:ADC tempx:STA tempx

  DEC tempy
  BNE loop

  RTS
}

.password
{
  ; Mark as invalid password
  LDA #&00:STA tempz

  ; Stop any music playing
  LDA #&00:STA sound_music

  ; Clear screen
  JSR cls

  ; Set palette
  LDA #PAL_GAME:JSR setpal

  ; Position text cursor to write prompt
  LDX #&07:LDY #&05
  JSR positiontextcursor

  LDX #&00
  LDA passwordstring, X
.nextchar
  STA sprite:JSR writetile
  INX
  LDA passwordstring, X
  BNE nextchar

  JSR flushallbuffers
  ; acknowledge any ESC prior to password input
  LDA #&7E:JSR OSBYTE

  ; Position text cursor for entry
  LDX #&06:LDY #&0E
  JSR positiontextcursor

  ; read password input

  ; set current string length to 0
  LDA #&00:STA tempx
.back
  ; read a character from keyboard
  JSR OSRDCH

  ; is it ESC (0x27)?
  CMP #&1B
  BNE noescape
  ; acknowledge ESC
  LDA #&7E:JSR OSBYTE
  ; password entry cancelled
  RTS

.noescape
  ; is it DEL (0x7f)?
  CMP #&7F
  BNE nodel
  ; is string length 0
  LDA tempx
  BEQ back
  ; reduce string length
  DEC tempx

  ; Move to previous character position
  LDA sprdst:SEC:SBC #&10:STA sprdst
  BCS samepage
  DEC sprdst+1
.samepage
  ; write a blank char
  LDA #'_':STA sprite:JSR writetile

  ; Move to previous character position
  LDA sprdst:SEC:SBC #&10:STA sprdst
  BCS samepage2
  DEC sprdst+1
.samepage2
  JMP back

.nodel
  ; convert lowercase to uppercase
  AND #&DF
  ; is it outside valid range (A..P)?
  CMP #'A':BCC back
  CMP #'Q':BCS back
  STA sprite:JSR writetile

  ; add input to string
  AND #&0F:TAX:LDA codebyte, X
  LDY tempx
  STA password_buffer, Y
  ; increment string length
  INC tempx
  ; is string length < 20?
  LDA tempx:CMP #20:BCC back

  ; validate password string
  LDX #&00:STX seed
.passloop
  LDA password_buffer, X
  PHA
  CLC:ADC #&07
  CLC:ADC seed
  AND #&0F:STA password_buffer, X

  PLA
  STA seed
  INX
  CPX #20
  BNE passloop

  LDX #&00
.passloop2
  LDY #&04
  LDA #&00
.passloop3
  CLC:ADC password_buffer, X
  INX
  DEY
  BNE passloop3

  AND #&0F
  CMP password_buffer, X
  BNE done
  INX
  CPX #&0F
  BNE passloop2
  LDA password_buffer+4
  ASL A
  STA tempx
  LDA password_buffer+9
  ASL A
  CLC:ADC tempx:STA tempx
  LDA password_buffer+14
  ASL A
  CLC:ADC tempx

  LDX #&04
.passloop4
  CLC:ADC password_buffer+14, X
  DEX
  BNE passloop4

  AND #&0F
  CMP password_buffer+19
  BNE done

  ; apply decoded password values to in-game variables
  LDX #&00
  LDY #&00
.passloop5
  JSR getpassptr

  LDA password_buffer, Y
  STY tempy:LDY #&00:STA (stagemapptr), Y:LDY tempy
  INY
  CPY #20
  BNE passloop5

  ; Shift low nibble to high nibble of BONUS_POWER
  LDA tempu:ASL A:ASL A:ASL A:ASL A:STA BONUS_POWER

  ; Derive stage value by combining nibbles
  LDA tempw:ASL A:ASL A:ASL A:ASL A:ORA tempv:STA stage

  ; Mark as a valid password
  INC tempz

.done
  RTS

  ; Password prompt string
.passwordstring
  EQUS "ENTER:SECRET:CODE"
  EQUB &00

  ; Password decode translation codes (nibbles)
.codebyte
  EQUB &05, &00, &09, &04, &0D, &07, &02, &06, &0A, &0F, &0C, &03, &08, &0B, &0E, &01
}

; Get a pointer to the in-game variable for the X th password position
.getpassptr
{
  LDA passdatavars, X:STA stagemapptr
  LDA #&00:STA stagemapptr+1
  INX

  RTS

 ; Locations in zero page where the decoded password variables are placed
.passdatavars
  EQUB (score+6 MOD 256), (BONUS_REMOTE MOD 256), (tempv MOD 256), (score MOD 256), (tempp MOD 256)
  EQUB (score+5 MOD 256), (tempu MOD 256), (score+3 MOD 256), (BONUS_FIRESUIT MOD 256), (tempq MOD 256)
  EQUB (BONUS_BOMBS MOD 256), (score+2 MOD 256), (BONUS_SPEED MOD 256), (score+1 MOD 256), (tempr MOD 256)
  EQUB (score+4 MOD 256), (DEBUG MOD 256), (tempw MOD 256), (BONUS_NOCLIP MOD 256), (temps MOD 256)
}

.gamecompleted
{
  JSR cls
  LDA #PAL_GAME:JSR setpal

  LDY #&00 ; Position within current string
  LDX #&07 ; Num. strings to write

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

  ; Draw a row of blocks
  LDX #&00
  LDA #0:STA sprx
  LDA #&0B:STA spry
  LDA #&1A:STA sprite

.loop
  JSR drawbigtile

  INC sprx

  INX
  CPX #16
  BNE loop

  LDA #&07:STA sound_music

  ; Draw bomberman
  LDA #&10:STA BOMBMAN_FRAME
  LDA #&0A:STA BOMBMAN_Y
  LDA #&0F:STA BOMBMAN_X
  JSR waitvsync
  JSR drawbomberman

.run
  JSR waitvsync

  JSR drawbomberman

  DEC BOMBMAN_X:LDA BOMBMAN_X
  BPL noreset
  LDA #&0F:STA BOMBMAN_X

.noreset
  INC BOMBMAN_FRAME
  LDA BOMBMAN_FRAME:CMP #&13
  BNE framecycle
  LDA #&10:STA BOMBMAN_FRAME
.framecycle
  JSR drawbomberman

  JMP run

  RTS

.nextchar
  LDA winnertext, Y
  INY
  RTS

.winnertext
  EQUB &80, &00
  EQUS "CONGRATULATIONS"
  EQUB &FF

  EQUB &40, &06
  EQUS "YOU:HAVE:SUCCEEDED:IN"
  EQUB &FF

  EQUB &20, &0A
  EQUS "HELPING:BOMBERMAN:TO:BECOME"
  EQUB &FF

  EQUB &20, &0E
  EQUS "A:HUMAN:BEING"
  EQUB &FF

  EQUB &40, &12
  EQUS "MAYBE:YOU:CAN:RECOGNISE:HIM"
  EQUB &FF

  EQUB &20, &16
  EQUS "IN:ANOTHER:HUDSON:SOFT:GAME"
  EQUB &FF

  EQUB &B0, &1C
  EQUS "GOOD:BYE"
  EQUB &FF
}

