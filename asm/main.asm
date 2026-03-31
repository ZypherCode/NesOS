.include "constants.inc"

.segment "CODE"
.import execute
.import stdout_buffer
.import stdin
.import last_key
.import printl
.import hello_string
.import cursor_y
.import stdin_write_ptr
.import timer
.import show_cursor
.import read_ptr
.import write_ptr
.import need_clear
.import symb
.import cursor_x
.import blink_counter

.export wait_for_input
.proc wait_for_input
  LDX #$00
  LDA #$00
  clear_stdin:
  CPX #$ff
  BEQ end
  STA stdin,X
  INX
  JMP clear_stdin
  end:
  LDA #$00
  STA stdin_write_ptr

  forever:

  LDA last_key
  BEQ forever
  

  CMP #$ff
  BEQ exec

  CMP #04
  BEQ inc_symb ; Up pressed

  CMP #05
  BEQ dec_symb ; Down pressed

  CMP #01
  BEQ add_symb ; A pressed

  CMP #02
  BEQ jmp_symb ; B pressed

add_symb:
  LDA symb
  LDX write_ptr
  STA stdout_buffer,X
  INC write_ptr  
  
  LDX stdin_write_ptr
  STA stdin,X
  INC stdin_write_ptr

  LDA #$00
  STA symb
  JMP pass_out
  
inc_symb:
  INC symb
  LDA symb
  CMP #$60
  BNE pass_out
  LDA #$00
  STA symb
  JMP pass_out

jmp_symb:
  CLC
  LDA symb
  ADC #$10
  STA symb
  CMP #$60
  BNE pass_out
  LDA #$00
  STA symb
  JMP pass_out

dec_symb:
  DEC symb
  LDA symb
  CMP #$ff
  BNE pass_out
  LDA #$5e
  STA symb
  JMP pass_out

pass_out:
  LDA #$00
  STA last_key

  JMP forever

exec:
  LDA #$00
  STA last_key
  LDA #$ff
  LDX stdin_write_ptr
  STA stdin,X
  INC stdin_write_ptr
  LDA #$00
  STA symb

  RTS
.endproc

.proc main_loop
  forever:
  JSR wait_for_input

  JSR execute
  JMP forever
  RTS
.endproc

.export main
.proc main
  ; filling paletts
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  LDA #$0f
  STA PPUDATA
  LDA #$26
  STA PPUDATA
  LDA #$33
  STA PPUDATA
  LDA #$32
  STA PPUDATA

  ; init variables
  LDX #$00
  STX PPUMASK
  STX cursor_x
  STX symb
  STX need_clear
  STX write_ptr
  STX read_ptr
  STX show_cursor
  STX timer
  STX stdin_write_ptr
  STX blink_counter
  STX last_key
  LDX #$01
  STX cursor_y 

  ; Clear bufers
  LDX #$00
  LDA #$00
clear_bfr:
  CPX #$ff
  BEQ end_clear_bfr
  STA stdin,X
  STA stdout_buffer,X
  STA $0200,X  ; Clear garbage sprites in OAM
  INX
  JMP clear_bfr
  end_clear_bfr:

  ; add cursor sprite
  LDA #$08  ; Y
  STA $0200
  LDA #$3f  ; ID in ascii.chr
  STA $0201
  LDA #$00
  STA $0202 ; Flags
  LDA #$0
  STA $0203 ; X

  ; Print hello
  LDX #<hello_string
  LDY#>hello_string
  JSR printl

  ; enable nmi
  LDA #%00011110
  STA PPUMASK

  JSR main_loop

.endproc
