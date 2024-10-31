;**********************************************
RUNFILE: ;std
  CALL PRINT_NEWLINE
  LXI H,LINEBUF
  MVI C,'.'
  CALL STRCHR
  JNC RUNF1
  LXI D,DOTRK
  CALL STRCPY
RUNF1:  LXI D,LINEBUF
  CALL F_OPEN
  JC C_DIRNO ; no file
RD_4B:
  LXI H,LINEBUF
  MVI C,'.'
  CALL STRCHR
  INX H
  mov A,M
  CPI 'M'
  JNZ RD_4B1
  INX H
  mov A,M
  CPI 'O'
  JNZ RD_4B1
  INX H
  mov A,M
  CPI 'N'
  JNZ RD_4B1
  LXI H,0c000h
  LXI B,02000h
  PUSH H ;сохраняем адрес старта, а ret после F_READ сделает переход на этот адрес
  JMP RD_MON
RD_4B1:
  LXI B,4 ; читаем из RK? файла адрес старта программы/куда складывать в памяти и конец до которого складываем данные в памяти
  LXI H,LINEBUF
  push H
  CALL F_READ
  pop H
  MOV e,M
  INX H
  MOV d,M
  INX H
  MOV A,M
  INX H
  MOV b,M
  SUB E
  MOV c,A
  MOV A,b
  SBB D
  MOV b,A
  INX B  ;размер файла
  XCHG
  PUSH H ;сохраняем адрес старта, а ret после F_READ сделает переход на этот адрес
  mov A,H
  call PRHEX
  mov A,L
  call PRHEX
  push B
  MVI C,','
  CALL PUTC
  pop B
  mov A,B
  call PRHEX
  mov A,C
  call PRHEX
RD_MON:
  CALL F_READ
  jmp SD_OFF
