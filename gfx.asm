; Wait for vertical trace
.waitvsync
{
  TXA:PHA

  LDA #&13
  JSR OSBYTE

  PLA:TAX

  RTS
}

; Palettes
PAL_BLANK = &00
PAL_TITLE = &01
PAL_GAME  = &02
PAL_DBG   = &03

; Set palette to one specified in A
.setpal
{
  ASL A:ASL A:ASL A:TAY
  LDX #&00
.loop
  LDA #&13:JSR OSWRCH
  LDA paltable, Y:JSR OSWRCH:INY:INX
  LDA paltable, Y:JSR OSWRCH:INY:INX
  LDA #&00:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH
  CPX #&08
  BNE loop

  RTS

.paltable
  ; blank palette
  ; black, black, black, black
  EQUB 0,0, 1,0, 2,0, 3,0

  ; Title palette
  ; black, red, white, yellow
  EQUB 0,0, 1,1, 2,7, 3,3

  ; Game palette
  ; black, blue, red, white
  EQUB 0,0, 1,4, 2,1, 3,7

  ; Debug palette
  ; cyan, magenta, yellow, black
  EQUB 0,6, 1,5, 2,3, 3,0
}

; Clear graphics screen
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

; Write an 8x8 tile to screen at current cursor position, then advance
.writetile
{
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Store a pointer to spritesheet
  LDA #(swrtilesheet) MOD 256:STA sprsrc
  LDA #(swrtilesheet) DIV 256:STA sprsrc+1

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

  ; Is sprite > 'Z'
  CMP #&5B
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

  ; Advance to next 8x8 tile position
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

.drawbigtile
{
  TXA
  PHA
  TYA
  PHA

  ; Store a pointer to tilesheet top half
  LDA #(swrtilesheet) MOD 256:STA sprsrc
  LDA #(swrtilesheet) DIV 256:STA sprsrc+1

  ; Store a pointer to tilesheet bottom half
  LDA #(swrtilesheet+&20) MOD 256:STA sprsrc2
  LDA #(swrtilesheet+&20) DIV 256:STA sprsrc2+1

  LDA #&40:STA sprnext

  ; See how tile is laid out in tilesheet
  LDA sprtile
  BEQ inline

  LDA #&20:STA sprnext

  ; Store a pointer to tilesheet bottom half
  LDA #(swrtilesheet+&100) MOD 256:STA sprsrc2
  LDA #(swrtilesheet+&100) DIV 256:STA sprsrc2+1

.inline

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
  ADC sprnext
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
  ADC sprnext
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
  LDA #(swrspritesheet) MOD 256:STA sprsrc
  LDA #(swrspritesheet) DIV 256:STA sprsrc+1

  LDA #(swrspritesheet+&100) MOD 256:STA sprsrc2
  LDA #(swrspritesheet+&100) DIV 256:STA sprsrc2+1

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

  LDA sprflip:BEQ noflip
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Flip the sprite horizontally
  LDY #&00:LDX #24
.fliploop

  ; Use look up table
  STY tempy
  LDA (sprsrc), Y:TAY:LDA flip_lut, Y:STA flip_upper, X
  LDY tempy
  LDA (sprsrc2), Y:TAY:LDA flip_lut, Y:STA flip_lower, X
  LDY tempy

  INX
  
  CPX #32:BNE nextcol:LDX #16:CLC:BCC same
 .nextcol
  CPX #24:BNE nextcol2:LDX #8:CLC:BCC same
 .nextcol2
  CPX #16:BNE same:LDX #0
 .same

  INY:CPY #&20:BNE fliploop

  ; Update source pointer to flip buffer
  LDA #flip_upper MOD 256:STA sprsrc
  LDA #flip_upper DIV 256:STA sprsrc+1

  LDA #flip_lower MOD 256:STA sprsrc2
  LDA #flip_lower DIV 256:STA sprsrc2+1
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.noflip

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Add x offset
  LDA spru
  BEQ no_x_offs
  ASL A
  AND #&F8
  CLC:ADC sprdst:STA sprdst
  BCC no_x_offs ; Check for page boundary crossed
  INC sprdst+1
.no_x_offs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Add y offset
  LDA sprv
  BEQ no_y_offs
  LSR A:LSR A:LSR A
  ASL A
  CLC:ADC sprdst+1:STA sprdst+1
.no_y_offs
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; Calculate bottom part as being + 0x200 from top
  LDA sprdst:STA sprdst2
  LDA sprdst+1:CLC:ADC #&02:STA sprdst2+1

  ; Now draw it
  LDY #&00
.loop
  ; Top half
  LDA (sprsrc), Y
  LDX sprsolid:BNE solidtop
  EOR (sprdst), Y
.solidtop
  STA (sprdst), Y

  ; Bottom half
  LDA (sprsrc2), Y
  LDX sprsolid:BNE solidbottom
  EOR (sprdst2), Y
.solidbottom
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

