; OS defines
INCLUDE "os.asm"

; Variable and constant defines
INCLUDE "consts.asm"

; Zero page vars
ORG &50

INCLUDE "exomizer310decruncher.h.asm"

ORG EXO_LOAD_ADDR

.start
{
  LDX #lo(xscr)
  LDY #hi(xscr)
  LDA #hi(MODE2BASE)

  jsr decrunch_to_page_A

  ; Back to OS
  RTS
}

include "exomizer310decruncher.asm"

.xscr
INCBIN "XSCR"
.end

SAVE "EXOSCR", start, end
