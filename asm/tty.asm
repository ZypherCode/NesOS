.segment "ZEROPAGE"
  str_ptr: .res 2
  cmd_ptr: .res 2
  arg_ptr: .res 2

.segment "BSS"
  args_start_at: .res 1

.segment "CODE"
.import invite
.import stdin_write_ptr
.import printl
.import stdin
.import stdout_buffer
.import write_ptr
.import last_key
.import cls

.import wait_for_input

.export execute
.proc execute
  LDA #$00
  STA last_key

  LDA #$fd
  LDY write_ptr
  STA stdout_buffer,Y
  INC write_ptr

  ; skip empty line
  LDA stdin
  CMP #$ff
  BEQ empty

  LDX #$00 
  read_table_line:
  LDA commands,X
  STA str_ptr 
  INX
  LDA commands,X
  STA str_ptr+1 
  ORA str_ptr
  BEQ not_found
  INX
  LDA commands,X
  STA cmd_ptr 
  INX
  LDA commands,X
  STA cmd_ptr+1 
  INX

    ; Compare string at str_ptr with stdin
    LDY #$00        ; X = индекс (можно и Y, но у тебя Y занят таблицей)
  compare_loop:
    LDA (str_ptr),Y       ; берём символ команды
    CMP #$ff
    BEQ end_of_command    ; команда закончилась

    CMP stdin,Y           ; сравниваем
    BNE read_table_line

    INY
    JMP compare_loop

  not_found: 
  LDX #<command_not_found
  LDY#>command_not_found
  JSR printl
  JMP empty

end_of_command:
  LDA stdin,Y
  CMP #$ff
  BEQ found            ; ровно совпало

  CMP #$00             ; пробел?
  BEQ found_with_args  ; есть аргументы

  JMP read_table_line  ; иначе это "helpme" → не подходит

found:
  LDA #$ff
  STA args_start_at    ; нет аргументов
  JMP call_command

found_with_args:
  INY                  ; пропускаем пробел
  STY args_start_at    ; сохраняем индекс аргументов

call_command:
  LDA #>empty
  PHA
  LDA #<empty
  PHA
  JMP (cmd_ptr)

empty:
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

.proc arg_to_ptr 
  LDA #<stdin
  CLC
  ADC args_start_at
  STA arg_ptr

  LDA #>stdin
  ADC #$00
  STA arg_ptr+1
  RTS
.endproc

.proc cmd_help
  JSR cls
  LDX #<help_text
  LDY#>help_text
  JSR printl
  RTS
.endproc

.proc cmd_ver
  JSR cls
  LDX #<ver_text
  LDY#>ver_text
  JSR printl
  RTS
.endproc

.proc cmd_echo
  JSR arg_to_ptr
  LDX arg_ptr
  LDY arg_ptr+1
  JSR printl

  RTS
.endproc

.segment "RODATA"
help_text:
  .byte $0, $0, $0, $0, $0, $0, $0, $0
  .byte $21, $56, $49, $41, $42, $4c, $45, $0, $43, $4f, $4d, $4d, $41, $4e, $44, $53, $1a, $fd, $fd
  .byte $0, $a, $0, $48, $0, $d, $d, $0, $4f, $50, $45, $4e, $0, $54, $48, $49, $53, $0, $50, $41, $47, $45, $fd
  .byte $0, $a, $0, $56, $45, $52, $0, $d, $d, $0, $47, $45, $54, $0, $56, $45, $52, $53, $49, $4f, $4e, $0, $49, $4e, $46, $4f, $ff

ver_text:
  .byte $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $36, $45, $52, $53, $49, $4f, $4e, $0, $49, $4e, $46, $4f, $fd
  .byte $0, $a, $0, $2e, $45, $53, $2f, $33, $0, $10, $e, $11, $0, $41, $4c, $50, $48, $41, $0, $8, $4e, $4f, $4e, $d, $53, $54, $41, $42, $4c, $45, $9
  .byte $0, $0, $42, $59, $0, $3a, $59, $50, $48, $45, $52, $23, $4f, $44, $45, $fd, $fd
  .byte $0, $27, $49, $54, $28, $55, $42, $1a, $0, $3a, $59, $50, $48, $45, $52, $23, $4f, $44, $45, $f, $2e, $45, $53, $2f, $33, $fd, $ff

command_not_found:
  .byte $23, $4f, $4d, $4d, $41, $4e, $44, $0, $4e, $4f, $54, $0, $46, $4f, $55, $4e, $44, $fd, $ff

help_str:
  .byte $48, $ff

ver_str:
  .byte $56, $45, $52, $ff

echo_str:
  .byte $45, $43, $48, $4f, $ff

commands:
  .word ver_str, cmd_ver
  .word help_str, cmd_help
  .word echo_str, cmd_echo
  .word $0000