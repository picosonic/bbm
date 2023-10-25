; OS defines
INCLUDE "os.asm"
INCLUDE "inkey.asm"
INCLUDE "internal.asm"

; Variable and constant defines
INCLUDE "consts.asm"
INCLUDE "vars.asm"

ORG &00
CLEAR &00, &FF
.plingboot
EQUS "*BASIC", &0D ; Reset to BASIC
EQUS "PAGE=&1200", &0D ; Set PAGE to first file buffer (as we don't open any files from BASIC)
EQUS "*FX21", &0D ; Flush buffer
EQUS "CLOSE#0:CH.", '"', "LOADER", '"', &0D ; Close "!BOOT" and run the main code
EQUS "REM https://github.com/picosonic/bbm/", &0D ; Repo URL
EQUS "REM BBM build ", TIME$ ; Add a build date
.plingend
SAVE "!BOOT", plingboot, plingend

INCLUDE "loader2.asm"
SAVE "LOADER", basicstart, basicend, &FF8023, &FF1900

ORG MAIN_RELOC_ADDR
CLEAR MAIN_RELOC_ADDR, MAIN_RELOC_ADDR+&2000
GUARD ROMSBASE

.start

  PAGE_SWRDATA

.codestart
  JMP init

; Import modules
INCLUDE "input.asm"
INCLUDE "rand.asm"
INCLUDE "menus.asm"
INCLUDE "gfx.asm"
INCLUDE "sound.asm"

.init
  ; Initialise cursor
  LDA #&00:STA cursor
  STA sprflip:STA sprsolid:STA sprtile

  ; Initialise game state
  LDA #YES:STA inmenu

  JSR init_bomberman

  ; Set up vsync event handler
  LDA #&00:STA framecounter:STA frames
  SEI
  LDA #eventhandler MOD 256:STA EVNTV
  LDA #eventhandler DIV 256:STA EVNTV+1
  CLI
  LDA #&0E:LDX #&04:JSR OSBYTE ; Enable vsync event handler

.gamestart

  LDA #YES:STA inmenu

  JSR waitvsync
  JSR drawtitle

  ; Start playing music
  LDA #&01:STA sound_music

.awaitkeys
  JSR rand

  ; Scan for RETURN
  LDA #INKEY_RETURN:JSR scankey
  BNE startpressed

  ; Scan for SPACEBAR
  LDA #INKEY_SPACE:JSR scankey
  BEQ awaitkeys

  ; toggle cursor
  LDA #&3A:JSR drawcursor ; Draw a blank on current position
  LDA cursor:EOR #&01:STA cursor
  LDA #&40:JSR drawcursor ; Draw cursor at new position

  LDA #INKEY_SPACE:JSR unpressed ; Wait for SPACEBAR to be released

  JMP awaitkeys

.init_bomberman
{
  ; Init bomberman sprite
  LDA #1:STA BOMBMAN_X:STA BOMBMAN_X+1
  LDA #2:STA BOMBMAN_Y:STA BOMBMAN_Y+1
  LDA #8:STA BOMBMAN_U:STA BOMBMAN_V:STA BOMBMAN_U+1:STA BOMBMAN_V+1
  LDA #0:STA BOMBMAN_FRAME:STA BOMBMAN_FRAME+1
  LDA #0:STA BOMBMAN_FLIP:STA BOMBMAN_FLIP+1

  RTS
}

.startpressed
{
  LDA cursor
  BEQ playgame

  ; Flip cursor
  LDA cursor:EOR #&01:STA cursor

  ; Password entry screen
  JSR password
  LDA tempz:BNE playgame+4
  JMP gamestart
}

; Handler for VBLANK event
.eventhandler
{
  ; Save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  INC framecounter
  INC frames

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  LDA inmenu:BNE menu

  ;LDA #PAL_DBG:JSR setpal

  JSR drawbomberman ; clear bomberman in old pos

  ; Cache
  LDA BOMBMAN_X:STA BOMBMAN_X+1
  LDA BOMBMAN_Y:STA BOMBMAN_Y+1
  LDA BOMBMAN_U:STA BOMBMAN_U+1
  LDA BOMBMAN_V:STA BOMBMAN_V+1
  LDA BOMBMAN_FRAME:STA BOMBMAN_FRAME+1
  LDA BOMBMAN_FLIP:STA BOMBMAN_FLIP+1

  JSR drawbomberman ; draw bomberman in new pos

  ;LDA #PAL_GAME:JSR setpal
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.menu

  JSR read_input
  JSR sound_eventvhandler

  ; Restore registers
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
}

.playgame
{
  ; Initialise bombs
  LDX #MAX_BOMB-1
  LDA #NO
.clearbombs
  STA BOMB_ACTIVE, X
  DEX
  BPL clearbombs

  STA BONUS_REMOTE

  ; Initialise scores
  LDX #&00
.scoreinit
  STA topscore, X
  STA score, X
  INX
  CPX #&07
  BNE scoreinit

  LDA #&01:STA stage
  JSR drawstagescreen

  ; Play stage screen melody
  LDA #&02:STA sound_music

  ; Wait for tune to finish
  JSR sound_waittune

  ; Generate level map
  JSR buildmap

  ; Set time limit
  LDA #SECONDSPERLEVEL:STA timeleft

  ; Set remaining lives
  LDA #LIVESPERLEVEL-1:STA lifeleft

  ; Clear the screen
  JSR cls

  ; Start playing music
  LDA #&03:STA sound_music

  ; Draw TIME/SCORE/LIVES
  JSR showstatus
  JSR drawtime
  LDA #&00
  STA frames:STA chain_reactions:STA exit_bombed
  STA bricks_destroyed

  ; Draw level
  LDX #&00:LDY #&00
  LDA #0:STA sprx
  LDA #1:STA spry

  LDA #levelmap MOD 256:STA stagemapptr
  LDA #levelmap DIV 256:STA stagemapptr+1

.loop
  LDA (stagemapptr), Y:CLC:ADC #24:STA sprite

  INC stagemapptr

  JSR drawbigtile

  INC sprx

  INX
  CPX #MAP_WIDTH
  BNE loop

  DEC stagemapptr

  ; Move down a row
  INC spry
  LDX #0:STX sprx

  INY
  CPY #MAP_HEIGHT
  BNE loop

  ; Draw bomberman
  JSR init_bomberman
  JSR drawbomberman

  LDA #NO:STA inmenu
}

.gameloop
{
  ; Check if game is paused
  JSR paused
  ; TODO JSR SPRD

  JSR process_inputs ; Check button presses
  JSR waitvsync

  JSR bombtick ; bomb timer operations
  ; TODO THINK
  JSR bombanim ; animate bombs
  JSR stagetimer ; tick game stage timer
  JSR checkflames ; flame operations

  ; check for keypress
  LDA #INKEY_ESCAPE:JSR scankey ; Scan for ESCAPE
  BEQ gameloop

  ; acknowledge ESC
  LDA #&7E:JSR OSBYTE

  ; Stop sprites being drawn (by vsync)
  LDA #YES:STA inmenu

  JSR drawgameoverscreen

  LDA #&09:STA sound_music

  ; wait for RETURN before clearing resume code
.endwait
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ endwait

  ; Stop end music playing (if it still is)
  LDA #NO:STA sound_music

  ; TODO
  JMP gamestart
}

.paused
{
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ not_paused
  LDA #YES:STA sound_disable
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed

.wait_start
  LDA #INKEY_RETURN:JSR scankey ; Scan for RETURN
  BEQ wait_start
  LDA #INKEY_RETURN:JSR unpressed ; Wait until it's not pressed
  LDA #NO:STA sound_disable

  ; Reset frame counter
  LDA #&00:STA frames

.not_paused
  RTS
}

.process_inputs
{
  ; If we are in the centre of a square check what is in it
  LDA BOMBMAN_U
  CMP #8
  BNE nocheck

  LDA BOMBMAN_V
  CMP #8
  BNE nocheck

  LDY BOMBMAN_Y
  JSR make_stage_ptr
  LDY BOMBMAN_X
  LDA (stagemapptr), Y

  ; Does this location contain the exit?
  CMP #MAP_EXIT
  BEQ nocheck ; TODO - Set to exit handler

  ; If this is not the bonus skip forward
  CMP #MAP_BONUS
  BNE nocheck

  ; BONUS found - clear map here
  LDA #MAP_EMPTY:STA (stagemapptr), Y

  STY tempx
  LDA BOMBMAN_Y:STA tempy
  LDA #SPR_EMPTY:STA sprite
  JSR drawsolidtile
  JSR drawbomberman

  ; TODO - apply bonus powerup

  ; Play powerup collected melody
  LDA #&04:STA sound_music

.nocheck

  LDX keys
  BEQ done

.case_right
  TXA:AND #PAD_RIGHT
  BEQ case_left
  JSR move_right

.case_left
  TXA:AND #PAD_LEFT
  BEQ case_up
  JSR move_left

.case_up
  TXA:AND #PAD_UP
  BEQ case_down
  JSR move_up

.case_down
  TXA:AND #PAD_DOWN
  BEQ case_action
  JSR move_down

.case_action
  TXA:AND #PAD_A
  BNE drop_bomb

  ; Check we have detonator
  LDA BONUS_REMOTE
  BEQ done

  TXA:AND #PAD_B
  BEQ done
  JSR detonate

.done
  RTS
}

.drop_bomb
{
  ; See if map is empty here
  LDY BOMBMAN_Y
  JSR make_stage_ptr
  LDY BOMBMAN_X:JSR checkmap:BNE done

  ; Centre bomberman
  JSR adjust_bombman_hpos
  JSR adjust_bombman_vpos

  ; Find non-active bomb slot
  LDX BONUS_BOMBS
.loop
  LDA BOMB_ACTIVE, X
  BEQ place_bomb
  DEX
  BPL loop

.done
  RTS
}

.place_bomb
{
  ; Place bomb onto map
  LDA #MAP_BOMB:STA (stagemapptr), Y

  ; Record where we placed it
  LDA BOMBMAN_X:STA BOMB_X, X
  LDA BOMBMAN_Y:STA BOMB_Y, X

  ; Start bomb timer
  LDA #&00:STA BOMB_TIME_ELAPSED, X
  LDA #160:STA BOMB_TIME_LEFT, X

  ; Mark bomb slot as active
  LDA #YES:STA BOMB_ACTIVE, X

  ; TODO - play sound effect 3

  ; Draw bomb
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry
  LDA #SPR_BOMB2:STA BOMB_FRAME, X:STA sprite
  JSR drawbigtile

  RTS
}

.move_down
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #SPR_HALFSIZE
  BCS nextcell
  INC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:INY
  JSR make_stage_ptr
  LDY BOMBMAN_X:JSR checkmap:BNE done

  JSR adjust_bombman_hpos
  INC BOMBMAN_V
  LDA BOMBMAN_V
  CMP #SPR_SIZE
  BNE done

  ; Move down to start of next cell
  LDA #&00
  STA BOMBMAN_V
  INC BOMBMAN_Y

.done
  ; Set animation frame (4..7)
  LDA #&04:LDY #&07:JSR setframe

  RTS
}

.move_up
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_V
  CMP #SPR_HALFSIZE+1
  BCC nextcell
  DEC BOMBMAN_V
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y:DEY
  JSR make_stage_ptr
  LDY BOMBMAN_X:JSR checkmap:BNE done

  JSR adjust_bombman_hpos
  DEC BOMBMAN_V
  BPL done

  ; Move down to start of next cell
  LDA #SPR_SIZE-1
  STA BOMBMAN_V
  DEC BOMBMAN_Y

.done
  ; Set animation frame (8..11)
  LDA #&08:LDY #&0B:JSR setframe

  RTS
}

.move_left
{
  ; Disable horizontal flip
  LDA #NO:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #SPR_HALFSIZE+1
  BCC nextcell
  DEC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y
  JSR make_stage_ptr
  LDY BOMBMAN_X:DEY:JSR checkmap:BNE done

  JSR adjust_bombman_vpos
  DEC BOMBMAN_U
  BPL done

  ; Move to start of next cell
  LDA #SPR_SIZE-1
  STA BOMBMAN_U
  DEC BOMBMAN_X

.done
  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

  RTS
}

.move_right
{
  ; Flip sprite horizontally
  LDA #YES:STA BOMBMAN_FLIP

  ; Are we on the edge of this cell
  LDA BOMBMAN_U
  CMP #SPR_HALFSIZE
  BCS nextcell
  INC BOMBMAN_U
  JMP done

.nextcell
  ; Check if we can move to the next cell
  LDY BOMBMAN_Y
  JSR make_stage_ptr
  LDY BOMBMAN_X:INY:JSR checkmap:BNE done

  JSR adjust_bombman_vpos
  INC BOMBMAN_U
  LDA BOMBMAN_U
  CMP #SPR_SIZE
  BNE done

  ; Move to start of next cell
  LDA #&00
  STA BOMBMAN_U
  INC BOMBMAN_X

.done
  ; Set animation frame (0..3)
  LDA #&00:LDY #&03:JSR setframe

  RTS
}

.adjust_bombman_hpos
{
  LDA BOMBMAN_U
  CMP #SPR_HALFSIZE
  BCC adjust_right ; < 8
  BEQ done         ; = 8
  DEC BOMBMAN_U
.done
  RTS

.adjust_right
  INC BOMBMAN_U
  RTS
}

.adjust_bombman_vpos
{
  LDA BOMBMAN_V
  CMP #SPR_HALFSIZE
  BCC adjust_down ; < 8
  BEQ done        ; = 8
  DEC BOMBMAN_V
.done
  RTS

.adjust_down
  INC BOMBMAN_V
  RTS
}

.setframe
{
  ; Is this the same set of animation frames?
  CMP BOMBMAN_FRAMESTART
  BEQ same

  ; Update the new animation frame set
  STA BOMBMAN_FRAME
  STA BOMBMAN_FRAMESTART

.same
  ; Limit animation updates to every 4th frame
  PHA:LDA framecounter:AND #&03:CMP #&02:BEQ anim:PLA:RTS

.anim
  PLA

  ; Move on to the next frame of this set
  INC BOMBMAN_FRAME
  ; Is this frame now out of range?
  CPY BOMBMAN_FRAME
  BCS done

  ; Reset to first frame of set
  STA BOMBMAN_FRAME

.done
  RTS
}

.detonate
{
  RTS
}

.checkmap
{
  LDA (stagemapptr), Y
  BEQ done ; empty

  CMP #MAP_EXIT:BEQ done ; exit
  CMP #MAP_BONUS:BEQ done ; bonus

  CMP #MAP_BRICK:BEQ has_noclip ; brick
  CMP #MAP_HIDDEN_EXIT:BEQ has_noclip ; hidden exit
  CMP #MAP_HIDDEN_BONUS:BEQ has_noclip ; hidden bonus

  CMP #MAP_BOMB:BEQ has_bombwalk ; bomb

.done
  RTS
}

.has_noclip
{
  LDA BONUS_NOCLIP
  EOR #&01

  RTS
}

.has_bombwalk
{
  LDA BONUS_BOMBWALK
  EOR #&01

  RTS
}

.drawbomberman
{
  LDA BOMBMAN_X+1:STA sprx:DEC sprx
  LDA BOMBMAN_Y+1:STA spry

  LDA BOMBMAN_U+1:CLC:ADC #SPR_HALFSIZE:STA spru
  LDA BOMBMAN_V+1:CLC:ADC #SPR_HALFSIZE:STA sprv

  LDX BOMBMAN_FRAME+1:LDA BOMBER_ANIM, X:STA sprite

  LDA BOMBMAN_FLIP+1:STA sprflip
  JSR drawsprite

  ; Reset sprite properties
  LDA #&00:STA spru:STA sprv:STA sprflip
}

.make_stage_ptr
{
  LDA multtaby, Y:STA stagemapptr
  LDA #levelmap DIV 256:STA stagemapptr+1

  RTS
}

.bombtick
{
  LDX #MAX_BOMB-1

.loop
  ; Skip this bomb if it's not active
  LDA BOMB_ACTIVE, X
  BEQ nextbomb

  ; See what's on the map where this bomb is
  LDY BOMB_Y, X
  JSR make_stage_ptr

  STY tempu
  LDY BOMB_X, X
  STY tempv
  LDA (stagemapptr), Y

  ; Check if it's a bomb
  CMP #MAP_BOMB
  BNE bombend

  ; Advance animation frame
  INC BOMB_TIME_ELAPSED, X

  ; Check for remote detonator (don't tick)
  LDA BONUS_REMOTE
  BNE nextbomb

  ; Reduce bomb fuse time remaining, then skip if time hasn't run out
  LDA framecounter:AND #&01:BNE nextbomb
  DEC BOMB_TIME_LEFT, X
  BNE nextbomb

  LDA #0

.bombend
  AND #7
  JSR explode

  ; Count chain reactions, limiting to 255
  LDA chain_reactions
  CMP #$FF
  BEQ explosion
  INC chain_reactions

.explosion
  JSR sound_explosion

  ; Remove bomb from map
  LDA #MAP_EMPTY:STA (stagemapptr), Y

  ; Set as inactive
  STA BOMB_ACTIVE, X

  ; Clear bomb sprite
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry
  LDA BOMB_FRAME, X:STA sprite
  JSR drawbigtile

.nextbomb
  DEX
  BPL loop

  RTS
}

.explode
{
  STX tempx ; Cache X and Y regs
  STY tempy
        
  TAY
  LDA explode_lut,Y ; Load from lookup table
  STA tempt
        
  LDA #MAP_RIGHT:JSR expand_flame
  LDA #MAP_UP:JSR expand_flame
  LDA #MAP_LEFT:JSR expand_flame
  LDA #MAP_DOWN:JSR expand_flame
  LDA #MAP_HERE:JSR expand_flame
        
  LDX tempx ; Restore X and Y regs
  LDY tempy

  RTS

.explode_lut
  EQUB &FF ; 0 Empty
  EQUB  3  ; 1 Concrete
  EQUB  4  ; 2 Brick
  EQUB  1  ; 3 Bomb
  EQUB  2  ; 4 Hidden exit
}

.expand_flame
{
  CMP tempt:BEQ done

  ; Cache direction
  STA temps

  TAX
  LDY #MAX_FIRE-1
  JSR FIND_FIRE_SLOT
  BMI done
  
  LDA tempu
  CLC:ADC FIRE_Y_OFFSET,X
  STA FIRE_Y,Y

  LDA tempv
  CLC:ADC FIRE_X_OFFSET,X
  STA FIRE_X,Y

  ; Restore direction
  LDA temps

  STA FIRE_EXTRA,Y
  STA FIRE_EXTRA2,Y

  LDA #YES:STA FIRE_ACTIVE,Y

.done
  RTS
}

.FIRE_Y_OFFSET
  EQUB 0,  0,&FF,  0,  1  ; Y offsets (here, right, up, left, down)
.FIRE_X_OFFSET
  EQUB 0,  1,  0,&FF,  0  ; X offsets (here, right, up, left, down)

; Find unused fire
.FIND_FIRE_SLOT
{
  LDA FIRE_ACTIVE, Y
  BEQ done

  DEY
  BPL FIND_FIRE_SLOT

.done
  RTS
}

.drawsolidtile
{
  PHA

  LDA tempx:STA sprx:LDA tempy:STA spry:INC spry
  LDA #1:STA sprsolid
  JSR drawbigtile
  LDA #0:STA sprsolid
  
  PLA

  RTS
}

.checkflames
{
  LDX #MAX_FIRE-1

.loop
  ; Skip this flame if it's not active
  LDA FIRE_ACTIVE, X
  BNE burning
.flame_advance
  JMP nextflame

.burning
  ; Point to map where flame[x] is, and store coordinates in tempx,tempy
  PHA
  LDY FIRE_Y, X:STY tempy
  JSR make_stage_ptr
  LDY FIRE_X, X:STY tempx
  PLA

  BPL loc_C7CB
  INC FIRE_ACTIVE, X
  LDA FIRE_ACTIVE, X
  CMP #&87
  BNE flame_advance

  LDA #0
  STA FIRE_ACTIVE, X ; Disable flame[x]
  STA (stagemapptr), Y ; Clear map
  PHA
  LDA #SPR_EMPTY:STA sprite:JSR drawsolidtile
  PLA
  BEQ flame_advance

.loc_C7CB
; Check for empty
  LDA (stagemapptr), Y
  TAY
  BEQ loc_C838

; Check for brick
  CPY #MAP_BRICK
  BNE IS_BOMB

  INC bricks_destroyed
  LDA #&80
  STA FIRE_ACTIVE, X
  JMP nextflame

; Check for bomb
.IS_BOMB
  CPY #MAP_BOMB
  BNE IS_HIDDEN_EXIT

  LDA FIRE_EXTRA, X
  ORA #&10

  LDY tempx:STA (stagemapptr), Y

  LDA #8:STA sprite:JSR drawsolidtile
  JMP loc_C830

; Check for hidden exit
.IS_HIDDEN_EXIT
  CPY #MAP_HIDDEN_EXIT
  BNE IS_HIDDEN_BONUS

  LDY tempx
  LDA #MAP_EXIT:STA (stagemapptr), Y

  LDA #15:STA sprite:JSR drawsolidtile
  JMP loc_C830

; Check for hidden bonus
.IS_HIDDEN_BONUS
  CPY #MAP_HIDDEN_BONUS
  BNE IS_EXIT

  LDY tempx
  LDA #MAP_BONUS:STA (stagemapptr), Y
  LDA #1:STA sprtile
  LDA #0
  ;CLC:ADC BONUS_TYPE ; TODO
  STA sprite:JSR drawsolidtile
  LDA #0:STA sprtile
  JMP loc_C830

; Check for exit then bonus
.IS_EXIT
  CPY #MAP_EXIT
  BEQ loc_C828

  CPY #MAP_BONUS
  BNE loc_C830

  LDY tempx
  LDA #MAP_EMPTY
  STA (stagemapptr), Y

  LDA #SPR_EMPTY:STA sprite:JSR drawsolidtile
  DEC exit_bombed

.loc_C828
  INC exit_bombed
  JSR process_enemies

; Put fire out
.loc_C830
  LDA #0
  STA FIRE_ACTIVE, X

.loc_C835
  JMP nextflame

; ------------------------------------------

.loc_C838
  LDA FIRE_EXTRA2, X
  CLC
  ADC #8
  STA FIRE_EXTRA2, X
  AND #&7F
  CMP #&48
  BCS IS_HIDDEN_EXIT
  LDA FIRE_EXTRA, X
  ;STA byte_36
  AND #7
  BEQ loc_C835
  TAY
  LDA #0
  STA FIRE_EXTRA, X
  LDA FIRE_X, X
  CLC
  ADC FIRE_X_OFFSET, Y
  STA tempx
  LDA FIRE_Y, X
  CLC
  ADC FIRE_Y_OFFSET, Y
  STA tempy
  LDY #&4F
  ;JSR sub_CBE5
  BNE nextflame
  LDA tempx
  STA FIRE_X, Y
  LDA tempy
  STA FIRE_Y, Y
  LDA #1
  STA FIRE_ACTIVE, Y
  ;LDA byte_36
  AND #7
  STA FIRE_EXTRA2, Y
  ;LDA byte_36
  CLC
  ADC #&10
  CMP BONUS_POWER
  BCC loc_C89E
  LDA #0
  STA FIRE_ACTIVE, Y
  LDA FIRE_EXTRA2, X
  ORA #&80
  STA FIRE_EXTRA2, X
  JMP loc_C8A1

.loc_C89E
  STA FIRE_EXTRA, Y

.loc_C8A1
  LDX #0
  STA FIRE_EXTRA, Y

.nextflame
  DEX
  BMI done
  JMP loop

.done
  RTS
}

.process_enemies
{
  RTS
}

; Animate frame for each active bomb
.bombanim
{
  LDX #MAX_BOMB-1

.loop
  ; Skip this bomb if it's not active
  LDA BOMB_ACTIVE, X
  BEQ nextbomb

  ; Skip this bomb if elapsed%16 not 0
  LDA BOMB_TIME_ELAPSED, X
  AND #&0F
  BNE nextbomb

  ; Cache X, Y position for this bomb
  LDA BOMB_X, X:STA sprx
  LDA BOMB_Y, X:STA spry:INC spry

  ; Concentrate on bits 0111 0000
  LDA BOMB_TIME_ELAPSED, X
  LSR A:LSR A:LSR A:LSR A
  AND #&03
  TAY
  ; Select bomb frame from lookup
  LDA BOMB_FRAME, X:STA sprite:JSR drawbigtile
  LDA bombframes, Y:STA BOMB_FRAME, X:STA sprite:JSR drawbigtile

.nextbomb
  DEX
  BPL loop

  RTS

.bombframes
  EQUB 33, 34, 33, 32
}

; Reduce time left by a second
.stagetimer
{
  LDA frames
  CMP #FPS
  BCC done

  ; Reset frame counter for this second
  LDA #&00:STA frames

; Here temporarily
  JSR drawtime
;  LDA #FPS:STA delayframes:JSR delay

  LDA timeleft
  CMP #255
  BEQ done
  DEC timeleft
  BNE done

  ; TODO remove all monsters
  ; TODO add a bunch of small monsters
  ; TODO respawn bonus

.done
  RTS
}

.drawtime
{
  ; Set text coordinates
  LDX #&05:LDY #&00:JSR positiontextcursor

  LDA timeleft
  CMP #255
  BNE someleft
  LDA #0
.someleft

  LDY #'0'
  SEC

.l1
  SBC #100
  BCC l2
  INY
  BNE l1

.l2
  ADC #&64
  CPY #'0'
  BNE l3
  LDY #':'
  STY sprite:JSR writetile

  JMP putnumber

.l3
  STY sprite:JSR writetile
  LDY #'0'
  SEC

.l4
  SBC #10
  BCC l5
  INY
  BNE l4

.l5
  ADC #':'
  STY sprite:JSR writetile
  STA sprite:JSR writetile

  RTS
}

.showstatus
{
  ; Set text coordinates
  LDX #&00:LDY #&00:JSR positiontextcursor

  ; Write "TIME"
  LDX #&03
.nextchar
  LDA timestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar

  ; Advance text coordinates
  LDA #&C0
  CLC:ADC sprdst:STA sprdst
  LDA #&01
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write trailing zeroes of score
  LDA #'0':STA sprite:JSR writetile:JSR writetile

  ; Advance text coordinates
  LDA #&40
  CLC:ADC sprdst:STA sprdst
  LDA #&00
  CLC:ADC sprdst+1:STA sprdst+1

  ; Write "LEFT"
  LDX #&03
.nextchar2
  LDA lifestring, X
  STA sprite:JSR writetile
  DEX
  BPL nextchar2

  ; Print lives remaining
  LDA lifeleft:JSR putnumber

  RTS

.timestring
  EQUS "EMIT"
.lifestring
  EQUS "TFEL"
}

.buildmap
{
  JSR addconcreteblocks

  ; Place exit (under brick) randomly on map
  JSR randomcoords
  LDA #MAP_HIDDEN_EXIT:STA (stagemapptr), Y

  ; Place bonus (under brick) randomly on map
  JSR randomcoords
  LDA #MAP_HIDDEN_BONUS:STA (stagemapptr), Y

  ; Place (stage + 25) bricks randomly
  LDA stage:CLC:ADC #25
  STA tempz

.nextbrick
  ; Place brick on map
  JSR randomcoords
  LDA #MAP_BRICK:STA (stagemapptr), Y

  DEC tempz
  BNE nextbrick

  RTS
}

.addconcreteblocks
{
  LDY #0
  JSR make_stage_ptr

  LDX #&00:JSR stagerow ; Top wall
  LDX #MAP_WIDTH:JSR stagerow ; Blank row
  LDX #MAP_WIDTH*2:JSR stagerow ; Alternate concrete
  LDX #MAP_WIDTH:JSR stagerow ; ...
  LDX #MAP_WIDTH*2:JSR stagerow
  LDX #MAP_WIDTH:JSR stagerow
  LDX #MAP_WIDTH*2:JSR stagerow
  LDX #MAP_WIDTH:JSR stagerow
  LDX #MAP_WIDTH*2:JSR stagerow
  LDX #MAP_WIDTH:JSR stagerow
  LDX #MAP_WIDTH*2:JSR stagerow
  LDX #MAP_WIDTH:JSR stagerow
  LDX #&00 ; Bottom wall

.stagerow
  LDA #MAP_WIDTH:STA tempx

.stagecell
  LDA stagerows, X
  STA (stagemapptr), Y
  INC stagemapptr

  INX
  DEC tempx
  BNE stagecell

  RTS

.stagerows
  EQUB 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
  EQUB 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
  EQUB 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1
}

; Find an empty position on the 15x13 map
.randomcoords
{
.loopx
  JSR rand
  ROR A:ROR A:ROR A ; A = A/8
  AND #&0F ; 0 to 15
  BEQ loopx
  CMP #MAP_WIDTH ; if A >= 15, try again
  BCS loopx
  STA tempx

.loopy
  JSR rand
  ROR A:ROR A:ROR A ; A = A/8
  AND #&0F ; 0 to 15
  BEQ loopy
  CMP #MAP_HEIGHT ; if A >= 13, try again
  BCS loopy
  STA tempy

  TAY

  JSR make_stage_ptr

  LDY tempx
  LDA (stagemapptr), Y ; Check what's on the map already
  BNE randomcoords ; If not blank, retry

  ; Make sure nothing is put too close to bomberman
  CPY #&03
  BCS done
  LDA tempy
  CMP #&03
  BCC randomcoords

.done
  RTS
}

; Level data lookup tables
.multtaby
  EQUB 0,MAP_WIDTH,MAP_WIDTH*2,MAP_WIDTH*3,MAP_WIDTH*4,MAP_WIDTH*5,MAP_WIDTH*6,MAP_WIDTH*7,MAP_WIDTH*8,MAP_WIDTH*9,MAP_WIDTH*10,MAP_WIDTH*11,MAP_WIDTH*12

; Delay specified number of frames
.delay
{
  LDA #&13:JSR OSBYTE ; Wait for vsync

  DEC delayframes
  BNE delay
  RTS
}

.usedmemory

ORG MAIN_LOAD_ADDR+MAX_OBJ_SIZE-(MAIN_LOAD_ADDR-MAIN_RELOC_ADDR)
.downloader
INCBIN "DOWNLOADER"
.codeend

ORG &0900
GUARD &0D00
.extradata
INCLUDE "extra.asm"
.extraend

; SWR data
ORG ROMSBASE
CLEAR ROMSBASE, OSBASE
GUARD OSBASE
.swrdata
INCLUDE "swrdata.asm"
.swrend

PUTFILE "EXOSCR", "$.EXOSCR", EXO_LOAD_ADDR
SAVE "EXTRA", extradata, extraend
SAVE "BDATA", swrdata, swrend, SWR_CACHE, SWR_CACHE
SAVE "BBM", start, codeend, DOWNLOADER_ADDR, MAIN_LOAD_ADDR

PRINT "-------------------------------------------"
PRINT "Zero page from &00 to ", ~zpend-1, "  (", ZP_ECONET_WORKSPACE-zpend, " bytes left )"
PRINT "VARS from &400 to ", ~end_of_vars-1, "  (", SOUND_WORKSPACE-end_of_vars, " bytes left )"
PRINT "EXTRA from ", ~extradata, " to ", ~extraend-1, "  (", NMI_WORKSPACE-extraend, " bytes left )"
PRINT "CODE from ", ~codestart, " to ", ~codeend-1, "  (", codeend-codestart, " bytes )"
PRINT "SWRDATA from ", ~swrdata, " to ", ~swrend-1, "  (", OSBASE-swrend, " bytes left )"
PRINT ""
remaining = MODE8BASE-usedmemory
PRINT "Bytes left before screen memory : ", ~remaining, "  (", remaining, " bytes )"
PRINT "-------------------------------------------"
