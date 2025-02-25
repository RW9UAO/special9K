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
  LXI B,1 ; ������ �� RKO ����� �� 0xE6
  LXI H,LINEBUF
  CALL F_READ
  DCX H
  MOV A,M
  CPI 0E6H
  JNZ RUNF2
  LXI B,20 ; ������ �� RKO ����� ����� ������ ���������/���� ���������� � ������ � ����� �� �������� ���������� ������ � ������
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
  INX B  ;������ �����
  XCHG
  PUSH H ;��������� ����� ������, � ret ����� F_READ ������� ������� �� ���� �����
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
C_LRD:  ; Orion ������ � SD � ������ � �������
  LXI D,LINEBUF+2
  CALL F_OPEN
  JC C_DIRNO ; no file
C_LRDF2:
  LXI B,8+64+1 ; ������ �� RKO ����� �� 0xE6
  LXI H,0
  CALL F_READ
  CPI 0E6H
  LXI H,LINEBUF
  JNZ PRINT_NEWLINE ; if not RKO simple return
  LXI B,4 ; ������ �� RKO ����� ����� ������ ���������/���� ���������� � ������ � ����� �� �������� ���������� ������ � ������
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
;  INX B  ;������ �����
  XCHG
  PUSH H ;��������� ����� ������
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
  LXI B,16 ; ������ �� RKO ����� ����� ������ ���������/���� ���������� � ������ � ����� �� �������� ���������� ������ � ������
  LXI H,LINEBUF+2
  CALL F_READ

  POP B
  LXI H,0 ; �������� � ����
  CALL F_READ ; reading
  mvi A,'B'
  call 0BFD6h ;WND ;���������� ���� �
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; ���������� ��� �����
  LXI H,0 ; ��������� ����� ����
  pop D ; �������� ����� ����� �����
  dcx D
  call 0BFCAh ;WATF ; 
  call 0BFF7h ;WFILE ; ������ ����� � RAM Disk
  pop H ; � HL ��������� �����
  call 0BFBEh ;ADRP ; ���������� ����� ��������
  LXI H,RWR_OK
  JMP PRINT

C_SRD: ; Orion ������ � �������� � ������ �� SD
  LXI H,LINEBUF+1
C_SRR1:
  INX H
  MOV A,M
  CPI 2CH
  JNZ C_SRR1
  xra A ;A=0
  mov M,A
  inx H
  push H ; �������� ������ ������ � ������ ����� �� SD
  mvi A,'B'
  call 0BFD6h ;WND ;���������� ���� �
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; ���������� ��� �����
  call 0BFE5h ;PSCF ; ����� �����
  cpi 0FFh ; ���� ���� ����, �� A=0FFh, ����� �����
  JNZ C_DIRNO_POPH ; no file
  pop D ; ������������ ������ ������ � ������ ����� �� SD
  CALL F_OPEN
  JC C_DIRNO ; no file
  LXI D,0000h
  LXI H,LINEBUF+2
  mvi c,7  ;�� ��������� ������ � ������ �� RAM ����� ����� ��� � ������� OrDos
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
  call 0BFD6h ;WND ;���������� ���� �
  LXI H,LINEBUF+2
  call 0BFD0h ;SDMA ; ���������� ��� �����
  call 0BFE5h ;PSCF ; ���������� ��� ����� ��� ������
  call 0BFC7h ; ATFM ������ ���������, �� ������: HL-StartAddr, DE-Size
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
  mvi c,15  ;�� ��������� ������ � ������ �� RAM ����� ����� ��� � ������� OrDos
C_SRD_LOOP5:
  MOV A,M
  STAX D
  INX D
  INX H
  DCR C
  JP C_SRD_LOOP5
  pop H ; ������� ��������
  DAD D ;HL=HL+DE
  push H
  XCHG ; DE<->HL ;  LXI H,8+64+1+4+16 ; � HL ��������� �����
  call 0BFBEh ;ADRP ; ���������� ����� �������� � ���� �� ��������� �� ������
  call 0BFFAh ;RFILE ; ��������� �� �������� � ���
  LXI H,0h
  pop D ; ������� �������� � ��������
  CALL F_WRITE
  pop H
  call 0BFBEh ;ADRP ; ���������� ���� ����� ��������
  LXI H,RWR_OK
  JMP PRINT
