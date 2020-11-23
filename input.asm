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