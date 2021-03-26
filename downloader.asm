; This does some initial setup and relocates main code to maximise RAM use

; OS defines
INCLUDE "os.asm"
INCLUDE "consts.asm"

downaddr = MAIN_LOAD_ADDR+&5000

ORG downaddr

  ; Make sure we are not in decimal mode
  CLD

  LDA #&8C:LDX #&0C:JSR OSBYTE ; Select TAPE filing system with 1200 baud (to turn off DFS)
  LDA #&0F:LDX #&00:JSR OSBYTE ; Flush all buffers
  LDA #&C9:LDX #&01:LDY #&00:JSR OSBYTE ; Kbd irqs off!
  LDA #&04:LDX #&01:JSR OSBYTE ; Disable cursor editing
  LDA #26:JSR OSWRCH ; Remove text window (tape needs this!)

  SEI

  ; Clear page ROM type table
  LDX #&0F:LDA #&00
.zaproms
  STA &2A1,X:DEX:BPL zaproms
 
  ; Clear zero page
  LDX #&9F
.clearzp
  STA 0,X:DEX:BNE clearzp
  STA 0

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

  JMP MAIN_RELOC_ADDR+&2200 ; Main entry point following relocation

PRINT "Saving downloader from ", ~downaddr, " to ", ~P%
SAVE "DOWNLOADER", downaddr, P%