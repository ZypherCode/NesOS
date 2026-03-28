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
.proc irq_handler
  RTI
.endproc

.proc clear_screen
  JSR get_coursor_raw

  LDX PPUSTATUS
  LDX coursor_raw_h
  STX PPUADDR
  LDX coursor_raw_l
  STX PPUADDR

  LDA #$00
  
  LDY #0
  start_clear:
  CPY #1
  BEQ break_clear
    LDX #0
    start_clear_line:
    CPX #32
    BEQ break_clear_line
    STA PPUDATA
    INX
    JMP start_clear_line
    break_clear_line:
  INY
  INC cursor_y
  DEC need_clear
  JMP start_clear
  break_clear:
  LDA need_clear
  BNE exit
  LDA #1
  STA cursor_y
  LDA #0
  STA cursor_x
  
exit:
  RTS
.endproc

.proc get_coursor_raw
  PHA  
  LDA cursor_y

  LDX #$20
  CMP #8
  BCC set_high_addr

  LDX #$21
  CMP #16
  BCC set_high_addr

  LDX #$22
  CMP #24
  BCC set_high_addr

  LDX #$23
  CMP #32
  BCC set_high_addr
  
  set_high_addr:
  STX coursor_raw_h
  
  ; low byte = y*32 + x 
  LDA cursor_y 
  ASL A 
  ASL A 
  ASL A 
  ASL A 
  ASL A 
  CLC 
  ADC cursor_x 
  STA coursor_raw_l
  PLA 
  RTS
.endproc

.proc new_line
  LDA #0 
  STA cursor_x 
  INC cursor_y 
  LDA cursor_y
  CMP #29 ; Lines max height
  BCC done
  LDA #0
  STA cursor_x
  STA cursor_y
  LDA #29
  STA need_clear
  done:
  JSR get_coursor_raw
  LDX PPUSTATUS
  LDX coursor_raw_h
  STX PPUADDR
  LDX coursor_raw_l
  STX PPUADDR
  RTS
.endproc

.proc draw_char ; A = tile 
  STA PPUDATA 
  INC cursor_x 
  LDA cursor_x 
  CMP #32 
  BNE done 
  JSR new_line
  done: 
  RTS 
.endproc

.proc read_joy1
  LDA current_input
  STA previous_input

  LDA #$01
  STA JOY1
  LDA #$00
  STA JOY1

LReadA:
  LDA $4016       ; Кнопка A
  AND #%00000001 
  bne press_a
  beq ReadB 

ReadB:
  LDA $4016       ; Кнопка B
  AND #%00000001 
  bne press_b 
  beq ReadSelect ; Переходим к чтению Select 
  
ReadSelect:
  LDA $4016       ; Кнопка B
  AND #%00000001 
  bne press_select
  beq release_all ; Переходим к чтению Select 

press_a:
  LDA #$21
  STA current_input
  JMP exit

press_b:
  LDA #$22
  STA current_input
  JMP exit

press_select:
  LDA #$ff
  STA current_input
  JMP exit

release_all:
  LDA #$00
  STA current_input
  JMP exit

exit:
  LDA previous_input
  CMP current_input
  BEQ stop
  LDA current_input
  STA last_key

stop:
  RTS
.endproc

.proc nmi_handler
  LDA need_clear
  BEQ normal
  JSR clear_screen
  JMP cont

normal:
  JSR read_joy1
  JSR get_coursor_raw

  LDX PPUSTATUS
  LDX coursor_raw_h
  STX PPUADDR
  LDX coursor_raw_l
  STX PPUADDR

  INC blink_counter
  LDA blink_counter
  CMP #15
  BNE skip

  LDA #$ff
  SBC show_cursor
  STA show_cursor

  LDA #0
  STA blink_counter

  INC timer

skip:
  ; Put buffer on screen
  LDX #8
  STX out_size
  LDX #$00
  while:
    LDA read_ptr
    CMP write_ptr
    BEQ break

    CPX out_size
    BCS break

    LDY read_ptr
    LDA stdout_buffer,Y
    CMP #$fd
    BNE draw
    JSR new_line
    LDY #1
    STY out_size
    JMP increment

    draw:
    JSR draw_char

    increment:
    INC read_ptr
    INX

    JMP while

  break:  
cont:
  LDA show_cursor
  BNE show

  LDA #$f1
  STA $0200
  JMP exit

show:
  ; cursor_x -> X пиксель
  LDA cursor_x
  CLC
  ASL A        ; *2
  ASL A        ; *4
  ASL A        ; *8
  STA $0203

  ; cursor_y -> Y пиксель
  LDA cursor_y
  CLC
  ASL A
  ASL A
  ASL A
  STA $0200

exit:
  LDA PPUSTATUS
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00  ; Отключить скроллинг
	STA $2005
	STA $2005
  RTI
.endproc

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
.endproc

.proc execute
  LDA #$00
  STA last_key

  LDA #$fd
  LDY write_ptr
  STA stdout_buffer,Y
  INC write_ptr

  LDX #<stdin
  LDY#>stdin
  JSR printl

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

  LDX #<invite
  LDY#>invite
  JSR printl

  RTS
.endproc

.proc printl
  STX ptr
  STY ptr+1
  LDY #$00
loop:
  LDA (ptr),Y
  CMP #$ff
  BEQ done
  PHA
  LDA write_ptr
  TAX
  PLA
  STA stdout_buffer,X

  INC write_ptr
  INY
  JMP loop
done:
  RTS
.endproc


.segment "RODATA"
hello_string:
  .byte $37, $45, $4c, $43, $4f, $4d, $45, $0, $54, $4f, $0, $2e, $45, $53, $2f, $33, $01, $fd, $fd
  .byte $39, $4f, $55, $0, $4e, $45, $45, $44, $0, $54, $4f, $0, $52, $45, $41, $44, $0, $54, $48, $45, $0, $4d, $41, $4e, $55, $41, $4c, $fd
  .byte $41, $4e, $44, $0, $47, $4f, $0, $54, $4f, $0, $41, $44, $44, $0, $53, $4f, $4d, $45, $0, $4e, $45, $57, $0, $46, $45, $41, $54, $55, $52, $45, $53, $1

invite:
  .byte $fd, $5e, $1e, $0, $ff

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
  .incbin "ascii.chr"
.segment "STARTUP"