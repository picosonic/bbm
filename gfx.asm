; Initialise mode 8
.mode8
{
  ; Mode 1 (320x256, 4 colours)
  LDA #&16:JSR OSWRCH
  LDA #&01:JSR OSWRCH

  ; Hide the cursor, reprogram display character
  LDA #&17:JSR OSWRCH
  LDA #&01:JSR OSWRCH
  LDA #&00:JSR OSWRCH
  JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH:JSR OSWRCH

  ; Hide the cursor, with cursor start register (in scanlines)
  LDA #&0A:STA CRTC00
  LDA #&20:STA CRTC01

  ; Set displayed chars per horizontal line (64) to match NES (256 pixels)
  LDA #&01:STA CRTC00
  LDA #&40:STA CRTC01

  ; Shift display horizontally to centre (in char widths from left)
  LDA #&02:STA CRTC00
  LDA #&59:STA CRTC01

  ; Set displayed chars per column (28) to match NES (240 pixels, with 224 displayed)
  LDA #&06:STA CRTC00
  LDA #&1C:STA CRTC01

  ; Shift display vertically to centre
  LDA #&07:STA CRTC00
  LDA #&21:STA CRTC01

  ; Change screen start to &4800 to gain an extra 6k bytes
  LDA #&0D:STA CRTC00
  LDA #(MODE8BASE) MOD 256:STA CRTC01
  LDA #&0C:STA CRTC00
  LDA #(MODE8BASE) DIV 256:LSR A:LSR A:LSR A:STA CRTC01

  RTS
}

; Wait for vertical trace
.waitvsync
{
  LDA #&13
  JSR OSBYTE

  RTS
}