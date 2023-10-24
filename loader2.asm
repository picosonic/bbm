; Origin set to where the BASIC code is loaded
ORG &1200

; Place in memory to check if writable
swrcheck=ROMSBASE+8

.basicstart

; Include preceding tokenised BASIC loader program
INCBIN "loadertok.bin"

; Align to next page boundary to allow space for BASIC
ALIGN &100

; Test slots to find first available SWRAM
.swrtest
{
  SEI

  LDY #&FF
  STY SWR_PAGEDATA:INY ; Mark as not found (yet)

.findswr
  STY ROMSEL
  LDA swrcheck:EOR #&55:STA swrcheck
  CMP swrcheck:BNE noswryet

  STY SWR_PAGEDATA
  BEQ swrdone ; Stop if we've found SWR
 
.noswryet
  INY:CPY #16:BNE findswr ; Keep looking until we get to slot 16

  ; Re-select ROM (likely BASIC)
.swrdone
  LDY ROMSEL_CACHE:STY ROMSEL

  CLI

  RTS
}

; Copy from main RAM &4000..&7FFF into SWRAM &8000..&BFFF
.swrcopy
{
  SEI

  ; Select the SWRAM slot we found earlier
  LDY SWR_PAGEDATA:STY ROMSEL

  LDX #&00
.swrcpyloop
  ; Copy a page of data
  LDA &4000, X:STA ROMSBASE, X
  INX
  CPX #&00:BNE swrcpyloop

  ; Advance src and dest pointers
  INC swrcpyloop+2:INC swrcpyloop+5

  ; See if src has got to the end
  LDA swrcpyloop+2
  CMP #&80:BNE swrcpyloop

  ; Re-select ROM (likely BASIC)
  LDY ROMSEL_CACHE:STY ROMSEL

  ; Put back source/dest incase further copies are done
  LDA #&40:STA swrcpyloop+2
  LDA #hi(ROMSBASE):STA swrcpyloop+5

  CLI

  RTS
}

.basicend
