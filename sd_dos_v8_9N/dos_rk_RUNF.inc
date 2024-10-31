;**********************************************
RUNFILE: ;RK-86
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
  LXI B,4 ; читаем из RK? файла адрес старта программы/куда складывать в памяти и конец до которого складываем данные в памяти
  LXI H,LINEBUF
  push H
  CALL F_READ
  pop H
  MOV D,M
  INX H
  MOV E,M
  INX H
  MOV B,M
  INX H
  MOV A,M
  SUB E
  MOV C,A
  MOV A,B
  SBB D
  MOV B,A
  INX B  ;размер файла
  XCHG
  PUSH H ;сохраняем адрес старта, а ret после F_READ сделает переход на этот адрес
  push B
  push B
  mov A,H
  call PRHEX
  mov A,L
  call PRHEX
  MVI C,','
  CALL PUTC
  mov A,B
  call PRHEX
  POP B
  mov A,C
  call PRHEX
  POP B
  CALL F_READ
  jmp SD_OFF
