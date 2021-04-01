; This does some initial setup and relocates main code to maximise RAM use
;
; Uses some ideas seen in Crazee Rider BBC Micro source (by Kevin Edwards)
;   https://github.com/KevEdwards/CrazeeRiderBBC

; OS defines
INCLUDE "os.asm"
INCLUDE "consts.asm"

ORG DOWNLOADER_ADDR

  ; Make sure we are not in decimal mode
  CLD

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

  ; Initialisation
  LDA #&8C:LDX #&0C:JSR OSBYTE ; Select TAPE filing system with 1200 baud (to turn off DFS)
  LDA #&0F:LDX #&00:JSR OSBYTE ; Flush all buffers
  LDA #&C9:LDX #&01:LDY #&00:JSR OSBYTE ; Kbd irqs off!
  LDA #&04:LDX #&01:JSR OSBYTE ; Disable cursor editing
  LDA #26:JSR OSWRCH ; Remove text window (tape needs this!)
  LDA #&8F:LDX #&0C:LDY #&FF:JSR OSBYTE ; Disable NMIs to claim absolute workspace (&E00)

  SEI

  ; Clear page ROM type table
  LDX #&0F:LDA #&00
.zaproms
  STA &2A1,X:DEX:BPL zaproms
 
  ; Clear zero page
  LDX #&8F
.clearzp
  STA 0,X:DEX:BNE clearzp
  STA 0

  LDX #&FF:TXS ; Clear stack

  CLI

  ; Clear variables in language workspace
.clearvars
  STA &400,X
  STA &500,X
  STA &600,X
  STA &700,X
  INX:BNE clearvars

  LDX #&00
  LDY #HI(MODE8BASE-MAIN_RELOC_ADDR) ; MAX program length in pages
.relocate
  LDA MAIN_LOAD_ADDR,X:STA MAIN_RELOC_ADDR,X
  INX:BNE relocate
  INC relocate+2
  INC relocate+5
  DEY:BNE relocate

  ; Define ENVELOPE
  LDA #&08
  LDX #envelope MOD 256
  LDY #envelope DIV 256
  JSR OSWORD

  ; Start game running
  JMP MAIN_RELOC_ADDR+&2200 ; Main entry point following relocation

.envelope
  ; "Marimba"
  EQUB 1   ; Envelope number
  EQUB 2   ; Length of each step (hundredths of a second) and auto repeat (top bit)
  EQUB 0   ; Change of pitch per step in section 1
  EQUB 0   ; Change of pitch per step in section 2
  EQUB 0   ; Change of pitch per step in section 3
  EQUB 0   ; Number of steps in section 1
  EQUB 0   ; Number of steps in section 2
  EQUB 0   ; Number of steps in section 3
  EQUB 60 ; Change of amplitude per step during attack phase
  EQUB -4  ; Change of amplitude per step during decay phase
  EQUB -4  ; Change of amplitude per step during sustain phase
  EQUB -4  ; Change of amplitude per step during release phase
  EQUB 60 ; Target level at end of attack phase
  EQUB 30  ; Target level at end of decay phase

PRINT "Saving downloader from ", ~DOWNLOADER_ADDR, " to ", ~P%
SAVE "DOWNLOADER", DOWNLOADER_ADDR, P%