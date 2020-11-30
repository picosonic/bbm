
.drawtitle
{
  ; Clear palette whilst drawing
  JSR blankpal
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
  JSR titlepal

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

.drawbonusscreen
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

  LDX #&0A
.nextchar
  LDA bonusstring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Advance two tile positions
  LDA sprdst:CLC:ADC #&20:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage

  RTS

.bonusstring
  EQUS "EGATS:SUNOB"
}

.drawgameoverscreen
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

  LDX #&08
.nextchar
  LDA gameoverstring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Advance two tile positions
  LDA sprdst:CLC:ADC #&20:STA sprdst
  BCC samepage
  INC sprdst+1
.samepage

  RTS

.gameoverstring
  EQUS "REVO:EMAG"
}
