.include "constants.inc" 

.segment "HEADER"
  .byte $4e, $45, $53, $1a, $02, $01, $00, $00

.segment "ZEROPAGE"
  ptr: .res 2

.segment "BSS"
  stdout_buffer: .res 256
  write_ptr: .res 1
  read_ptr: .res 1
  out_size: .res 1

  stdin: .res 256
  stdin_write_ptr: .res 1

  current_input: .res 1
  previous_input: .res 1
  last_key: .res 1

  need_clear: .byte 0
  blink_counter: .byte $00
  show_cursor: .byte 0
  color: .byte $00
  cursor_x: .byte 0   ; 0–31
  cursor_y: .byte 0   ; 0–29
  coursor_raw_l: .byte 0
  coursor_raw_h: .byte 0 ; $20 - $23
  symb: .byte $00

  timer: .res 1

.segment "CODE"
.export stdout_buffer
.export stdin
.export last_key
.export cursor_y
.export stdin_write_ptr
.export timer
.export show_cursor
.export read_ptr
.export write_ptr
.export need_clear
.export symb
.export cursor_x
.export ptr
.export blink_counter
.export coursor_raw_h
.export coursor_raw_l
.export out_size
.export current_input
.export previous_input

.export hello_string
.export invite

.import main
.import printl

.proc irq_handler
  RTI
.endproc

.import nmi_handler

.proc reset_handler
  SEI
  CLD
  LDA #%10010000   ; включить NMI
  STA PPUCTRL

  vblankwait:
    BIT PPUSTATUS
    BPL vblankwait
    JMP main
.endproc

.segment "RODATA"
hello_string:
  .byte $37, $45, $4c, $43, $4f, $4d, $45, $0, $54, $4f, $0, $2e, $45, $53, $2f, $33, $01, $fd, $fd
  .byte $34, $59, $50, $45, $0, $2, $48, $2, $0, $46, $4f, $52, $0, $48, $45, $4c, $50, $0, $49, $4e, $0, $43, $4f, $4d, $4d, $41, $4e, $44, $53, $fd
  .byte $4f, $52, $0, $2, $56, $45, $52, $2, $0, $46, $4f, $52, $0, $43, $48, $45, $43, $4b, $0, $54, $48, $45, $0, $56, $45, $52, $53, $49, $4f, $4e, $0e, $fd

invite:
  .byte $fd, $5e, $1e, $0, $ff

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
  .incbin "ascii.chr"
.segment "STARTUP"