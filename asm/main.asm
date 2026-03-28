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

.proc main_loop
  forever:
  LDA last_key
  BEQ forever
  LDX stdin_write_ptr
  STA stdin,X
  INC stdin_write_ptr

  CMP #$ff
  BEQ exec

  LDX write_ptr
  STA stdout_buffer,X
  INC write_ptr  
  JMP pass_out
  
pass_out:
  LDA #$00
  STA last_key

  JMP forever

exec:
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
  LDX #$01
  STX cursor_y 

  ; add cursor sprite
  LDA #$08
  STA $0200

  LDA #$3f
  STA $0201

  LDA #$00
  STA $0202

  LDA #$0
  STA $0203

  LDX #<hello_string
  LDY#>hello_string
  JSR printl

  ; enable nmi
  LDA #%00011110
  STA PPUMASK

  JSR main_loop

.endproc
