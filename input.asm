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

; Flush all input buffers
.flushallbuffers
{
  LDA #&0F
  LDX #&00
  JSR OSBYTE
  RTS
}

; Select only keyboard as input stream
.selectkeyboard
{
  LDA #&02
  LDX #&00
  JSR OSBYTE
  RTS
}