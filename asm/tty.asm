
.segment "CODE"
.import invite
.import stdin_write_ptr
.import printl
.import stdin
.import stdout_buffer
.import write_ptr
.import last_key

.export execute
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