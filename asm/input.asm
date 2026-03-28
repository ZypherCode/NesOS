.include "constants.inc"

.segment "CODE"
.import last_key
.import previous_input
.import current_input

.export read_joy1
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
