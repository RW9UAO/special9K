;;**********************************************
RUNFILE: ; Orion
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
;RD_4B:
RUNF2:
  LXI B,1 ; читаем из RKO файла до 0xE6
  LXI H,LINEBUF
  CALL F_READ
  DCX H
  MOV A,M
  CPI 0E6H
  JNZ RUNF2
  LXI B,20 ; читаем из RKO файла адрес старта программы/куда складывать в памяти и конец до которого складываем данные в памяти
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
;  RET
;#ifdef ORION
C_LRD:  ; Orion чтение с SD и запись в РАМдиск
  LXI D,LINEBUF+2
  CALL F_OPEN
  JC C_DIRNO ; no file
C_LRDF2:
  LXI B,8+64+1 ; читаем из RKO файла до 0xE6
  LXI H,0
  CALL F_READ
  CPI 0E6H
  LXI H,LINEBUF
  JNZ PRINT_NEWLINE ; if not RKO simple return
  LXI B,4 ; читаем из RKO файла адрес старта программы/куда складывать в памяти и конец до которого складываем данные в памяти
  LXI H,0
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
;  INX B  ;размер файла
  XCHG
  PUSH H ;сохраняем адрес старта
  push B
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
  call PRINT_NEWLINE
  LXI B,16 ; читаем из RKO файла адрес старта программы/куда складывать в памяти и конец до которого складываем данные в памяти
  LXI H,LINEBUF+2
  CALL F_READ

  POP B
  LXI H,0 ; загружаю с нуля
  CALL F_READ ; reading
  mvi A,'B'
  call 0BFD6h ;WND ;установить диск В
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; установить имя файла
  LXI H,0 ; начальный адрес ноль
  pop D ; конечный адрес равен длине
  dcx D
  call 0BFCAh ;WATF ; 
  call 0BFF7h ;WFILE ; запись файла в RAM Disk
  pop H ; в HL начальный адрес
  call 0BFBEh ;ADRP ; установить адрес загрузки
  LXI H,RWR_OK
  JMP PRINT

C_SRD: ; Orion чтение с РАМдиска и запись на SD
  LXI H,LINEBUF+1
C_SRR1:
  INX H
  MOV A,M
  CPI 2CH
  JNZ C_SRR1
  xra A ;A=0
  mov M,A
  inx H
  push H ; сохраняю начало записи с именем файла на SD
  mvi A,'B'
  call 0BFD6h ;WND ;установить диск В
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; установить имя файла
  call 0BFE5h ;PSCF ; поиск файла
  cpi 0FFh ; если есть файл, то A=0FFh, иначе выход
  JNZ C_DIRNO_POPH ; no file
  pop D ; устанавливаю начало записи с именем файла на SD
  CALL F_OPEN
  JC C_DIRNO ; no file
  LXI D,0000h
  LXI H,LINEBUF+2
  mvi c,7  ;из введенной строки с именем на RAM диске делаю имя в формате OrDos
C_SRD_LOOP3:
  MOV A,M
  CPI 0H
  JNZ C_SRD_LOOP4
  MVI A,20H
  DCX H
C_SRD_LOOP4:
  STAX D
  INX D
  INX H
  DCR C
  JP C_SRD_LOOP3
  mvi C,64
  xra A ;A=0
C_SRD_LOOPZ64:
  STAX D
  INX D
  DCR C
  JP C_SRD_LOOPZ64
  lxi D,8+64
  mvi A,0E6h
  STAX D
  mvi A,'B'
  call 0BFD6h ;WND ;установить диск В
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; установить имя файла
  call 0BFE5h ;PSCF ; установить имя файла для поиска
  call 0BFC7h ; ATFM чтение атрибутов, на выходе: HL-StartAddr, DE-Size
  push H
  push D
  mov A,H
  STA 8+64+1
  mov A,L
  STA 8+64+2
  DAD D
  mov A,H
  STA 8+64+3
  mov A,L
  STA 8+64+4

  LXI D,8+64+5
  LXI H,0000h
  mvi c,15  ;из введенной строки с именем на RAM диске делаю имя в формате OrDos
C_SRD_LOOP5:
  MOV A,M
  STAX D
  INX D
  INX H
  DCR C
  JP C_SRD_LOOP5
  pop H ; сколько записать
  DAD D ;HL=HL+DE
  push H
  XCHG ; DE<->HL ;  LXI H,8+64+1+4+16 ; в HL начальный адрес
  call 0BFBEh ;ADRP ; установить адрес загрузки с нуля со смещением на хеадер
  call 0BFFAh ;RFILE ; загрузить из РАМдиска в ОЗУ
  LXI H,0h
  pop D ; сколько записать с хеадером
  CALL F_WRITE
  pop H
  call 0BFBEh ;ADRP ; установить свой адрес загрузки
  LXI H,RWR_OK
  JMP PRINT
