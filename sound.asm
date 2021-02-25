.sound_init
{
  ; Define ENVELOPE
  LDA #&08
  LDX #envelope MOD 256
  LDY #envelope DIV 256
  JSR OSWORD

  RTS

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
}

; Stop playing melody
.sound_stop
  LDA #&00:STA sound_music

.sound_abort
  RTS

.sound_eventvhandler
{
  ; Check if melody playback disabled
  LDA sound_disable
  BNE sound_abort

  ; Check if any melody playing
  LDA sound_music
  BEQ sound_abort

  ; Check for init already done
  BMI update_melody

  ; Don't try to play melody > 10
  CMP #&0B:BCS sound_stop

  STA sound_temp

  ; Flag current melody as initialised
  ORA #&80:STA sound_music

  ; Make melody id 0 based
  DEC sound_temp

  ; Multiply by 8, for offset into melodies table
  LDA sound_temp:ASL A:ASL A:ASL A:TAY
  LDX #0

  ; Copy pointers to the three channels for current melody
.copy_pointers
  LDA sound_melodies_table, Y
  STA sound_chandat, X
  INY:INX:CPX #&06
  BNE copy_pointers

  ; Copy melody flags
  LDA sound_melodies_table, Y
  STA byte_D3 ; Duty cycle
  LDA sound_melodies_table+1, Y
  STA byte_D4

  ; Init sound parameters
  LDA #&00
  STA sound_cnt:STA sound_cnt+1:STA sound_cnt+2
  STA byte_D5
  STA byte_CD:STA byte_CD+1:STA byte_CD+2
  STA byte_D0:STA byte_D0+1:STA byte_D0+2
  
  LDA #&01
  STA sound_note_timeout:STA sound_note_timeout+1:STA sound_note_timeout+2
  STA sound_notelen:STA sound_notelen+1:STA sound_notelen+2
  STA byte_D6:STA byte_D6+1:STA byte_D6+2

  ; ** Don't worry about sound sweep **

.update_melody
  ; Start at 3rd channel, then work backwards
  LDA #&02:STA sound_chan

  ; Play something for this channel
.next_channel
  LDX sound_chan
  DEC sound_note_timeout, X
  BEQ play_channel

  ; Move on to next channel for this melody
.advance_channel
  DEC sound_chan
  BPL next_channel

  RTS

.play_channel
  ; Load the pointer for the current channel
  TXA:ASL A:TAX
  LDA sound_chandat, X:STA sound_ptr
  LDA sound_chandat+1, X:STA sound_ptr+1

  ; Check for a null pointer (if so then move on to next channel)
  ORA sound_ptr:BEQ advance_channel

;  LDA #&17:JSR sound_play_note

  JSR sound_write_regs
  JMP advance_channel
}

.sound_write_regs
{
  ; Get channel pointer
  LDX sound_chan
  LDY sound_cnt, X

  ; Read and cache next byte of channel data
  LDA (sound_ptr), Y:STA sound_temp

  ; Move channel pointer onwards
  INC sound_cnt, X

  ; Check for control byte
  LDA sound_temp:BMI control_byte

  ; Set current note timeout from current channel note length 
  LDA sound_notelen, X
  STA sound_note_timeout, X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  CPX #&02
  BEQ fix_triangle
  LSR A:LSR A
  CMP #&10
  BCC fix_delay
  LDA #&0F
  BNE fix_delay

.fix_triangle
  ASL A
  BPL fix_delay
  LDA #&7F

.fix_delay
  STA byte_D6, X
  LDA byte_D0, X
  BEQ loc_E57B
  LSR byte_D6, X

.loc_E57B
  ; Skip zeroes (rests)
  LDA sound_temp:BEQ abort_write

  ; Y = X * 4
  TXA:ASL A:ASL A:TAY

  LDA byte_CD, X
  BEQ loc_E59D
  BPL loc_E593
  INC byte_CD, X
  BEQ loc_E59D

.loc_E593
  LDA #&9F
  CPX #&02
  BNE loc_E5A1

.loc_E59D
  LDA byte_D6, X
  ORA byte_D3, X

.loc_E5A1
  ; STA sound_reg_base, Y
  LDA byte_CD, X
  CMP #&02
  BNE set_wavelen
  RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.set_wavelen
  ; Set sound channel (with flush enabled)
  TXA:ORA #&10:STA soundparams:INC soundparams

  LDA sound_temp
  ; Convert to BBC Micro note range
  CMP #&10:BCS inrange
  LDA #&10
.inrange
  SEC:SBC #&0F
  ASL A:ASL A

  JSR sound_play_note

.abort_write
  RTS

.control_byte
  ; Test to see if it's an "effect"
  AND #&F0:CMP #&F0:BEQ exec_effect

  ; Timing control
  LDA sound_temp:AND #&7F

  ; TODO *** Convert 60Hz note lengths to 50Hz ***

  STA sound_notelen, X
  JMP sound_write_regs

.exec_effect
  ; Determine which effect to action
  SEC:LDA #&FF:SBC sound_temp

  ; Use a case statement
  ASL A:TAY
  LDA off_E5E6+1, Y:PHA
  LDA off_E5E6, Y:PHA
  RTS

.off_E5E6
  EQUW effect_1-1
  EQUW effect_2-1
  EQUW effect_3-1
  EQUW effect_4-1
  EQUW effect_5-1
  EQUW effect_6-1
  EQUW effect_7-1
  EQUW effect_8-1
}

; FF
; Stop current playing melody
.effect_1
{
  LDA #&00:STA sound_music

  RTS
}

; FE
; Loop this channel back to the start
.effect_2
{
  LDA #&00:STA sound_cnt, X

  JMP sound_write_regs
}

; FD
.effect_3
{
  LDY sound_cnt, X
  LDA (sound_ptr), Y
  STA unk_CA, X
  INY
  STY sound_cnt, X
  STY unk_C7, X

  JMP sound_write_regs
}

; FC
.effect_4
{
  DEC unk_CA, X
  BEQ loc_E618
  LDA unk_C7, X
  STA sound_cnt, X

.loc_E618
  JMP sound_write_regs
}

; FB
.effect_5
{
  LDA byte_CD, X
  BEQ loc_E626
  LDA #&02
  STA byte_CD, X

  JMP sound_write_regs

.loc_E626
  LDA #&01
  STA byte_CD, X

  JMP sound_write_regs
}

; FA
.effect_6
{
  LDA #&FF
  STA byte_CD, X

  JMP sound_write_regs
}

; F9
.effect_7
{
  LDA #&FF
  STA byte_D0, X

  JMP sound_write_regs
}

; F8
.effect_8
{
  LDA #&00
  STA byte_D0, X

  JMP sound_write_regs
}

.sound_play_note
{
  ; Set pitch LSB
  STA soundparams+4

  ; Set all MSB to zero
  LDA #&00
  STA soundparams+1
  STA soundparams+3
  STA soundparams+5
  STA soundparams+7

  ; Use envelope 1 for amplitude
  LDA #&01
  STA soundparams+2
  ;LDA #&F1:STA soundparams+2
  ;LDA #&FF:STA soundparams+3
  ; Set duration of 1
  LDA #&01
  STA soundparams+6

  ; Set pointer to sound params in XY
  LDX #soundparams MOD 256
  LDY #soundparams DIV 256

  ; Action OS sound function
  LDA #&07:JSR OSWORD

  ; Go to next sound channel
  INC soundparams

.done
  RTS
}

.sound_waittune
{
  LDA sound_music
  BNE sound_waittune

  RTS
}

; ---------------------------------------------------------

.sound_disable
  EQUW &00

; Current melody channel data (3 x pointers, plus 2 bytes)
.sound_chandat
  EQUW &0000, &0000, &0000, &0000

; Current channel
.sound_chan
  EQUB &00

; Temporary APU storage
.sound_temp
  EQUB &00

; Current melody (top bit set if already initialised)
.sound_music
  EQUB &00

.sound_note_timeout
  EQUB &00, &00, &00

.sound_notelen
  EQUB &00, &00, &00

.byte_CD
  EQUB &00, &00, &00

.byte_D0
  EQUB &00, &00, &00

.byte_D3
  EQUB &00

.byte_D4
  EQUB &00

.byte_D5
  EQUB &00

.byte_D6
  EQUB &00, &00, &00

; Sound parameter block
.soundparams
  EQUB &00 ; Channel LSB
  EQUB &00 ; Channel MSB
  EQUB &00 ; Amplitude LSB
  EQUB &00 ; Amplitude MSB
  EQUB &00 ; Pitch LSB
  EQUB &00 ; Pitch MSB
  EQUB &00 ; Duration LSB
  EQUB &00 ; Duration MSB

; Melodies table
.sound_melodies_table
  EQUW melody_01_c1, melody_01_c2, melody_01_c3, &8080
  EQUW melody_02_c1, melody_02_c2, melody_02_c3, &4040
  EQUW &0000,        &0000,        melody_03_c3, &8080
  EQUW melody_04_c1, melody_04_c2, melody_04_c3, &8080
  EQUW melody_05_c1, melody_05_c2, melody_05_c3, &8080
  EQUW melody_06_c1, melody_06_c2, melody_06_c3, &8080
  EQUW melody_07_c1, melody_07_c2, melody_07_c3, &0040
  EQUW melody_08_c1, melody_08_c2, &0000,        &8080
  EQUW melody_09_c1, melody_09_c2, melody_09_c3, &8080
  EQUW melody_10_c1, melody_10_c2, melody_10_c3, &0040
  
; ---------------------------------------------------------