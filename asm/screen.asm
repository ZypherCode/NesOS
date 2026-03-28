.include "constants.inc"

.segment "CODE"

.import cursor_x
.import cursor_y
.import stdout_buffer
.import write_ptr
.import read_ptr
.import out_size
.import timer
.import show_cursor
.import blink_counter
.import coursor_raw_l
.import coursor_raw_h
.import need_clear
.importzp ptr
.import read_joy1

.export clear_screen
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

.export get_coursor_raw
.proc get_coursor_raw ; Обновить PPUADDR для текущего положения курсора.
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

.export new_line
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


.export draw_char
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

.export printl
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


.export nmi_handler
.proc nmi_handler
  LDA need_clear
  BEQ normal
  JSR clear_screen
  JMP cont

normal: ; Если очистка не нужна
  JSR read_joy1
  JSR get_coursor_raw

  LDX PPUSTATUS
  LDX coursor_raw_h
  STX PPUADDR
  LDX coursor_raw_l
  STX PPUADDR

  ; cursor blinking
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
  ; Если буфер обновился то выводим на экран изменения
  LDX #8
  STX out_size ; Символов за кадр (по-умолчянию 8)
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
    STY out_size ; New line - тяжело, снижаем out_size чтобы не пропускать символы
    JMP increment

    draw:
    JSR draw_char

    increment:
    INC read_ptr
    INX

    JMP while

  break:  
cont:
  ; проверка, показать или скрыть курсор
  LDA show_cursor
  BNE show

  ; убираем курсор
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