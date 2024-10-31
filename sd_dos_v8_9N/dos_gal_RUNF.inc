;**********************************************
RUNFILE: 
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
RD_G0:
  LXI B,6 ; читаем из GTP файла Block ID, block size and sync byte 0xa5
  LXI H,LINEBUF
  CALL F_READ
RD_G2:
  LXI H,LINEBUF
  MOV A,M
  CPI 010h
  JNZ RD_G1
RD_G3:
  LXI H,LINEBUF
  LXI B,1
  CALL F_READ
  CPI 0A5h
  JNZ RD_G3
RD_G1:
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
  CALL F_READ
  pop B ;not needed
  pop B ;not needed
  jmp SD_OFF

C_WB:
#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
  LXI D,LINEBUF+3
  CALL F_OPEN
  JC C_DIRNO ; no file
  LXI B,LINEBUF+15
  LXI D,02c36H-11
C_WB1:
  inx B
  inx D
  LDAX D
  STAX B
  xra A
  STAX D
  mov A,E
  cpi 35h
  jnz C_WB1

  LXI D,02c36H-5
  mvi A,0A5h
  STAX D
  inx D
  mvi A,036h
  STAX D
  inx D
  mvi A,02ch
  STAX D
  inx D
  LDA 02c38h
  adi 04h
  STA 02c34h
  LDA 02c39h
  jnc C_WB2
  adi 01h
C_WB2:
  STA 02c35h
  LXI H,02c32H
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
  INX B
  mvi A,06h
  add C
  mov A,C  ;size области
  jnc C_WB3
  inr B
C_WB3:
  LXI H,02c2ch ;АДРЕС  начала области
  CALL F_WRITE
  LXI D,LINEBUF+15
  LXI B,02c36H-11
C_WB4:
  inx B
  inx D
  LDAX D
  STAX B
  mov A,C
  cpi 35h
  jnz C_WB4
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
  LXI H,RWR_OK
  JMP PRINT

;g_putchr_rst_f: equ 0x0020    ; prints a character in A to the screen 
;at current cursor location.
PUTC:
 mov A,C
 call gPUTC
 ret

;g_printstr_f: equ 0x0937    ; prints a string pointed by DE
PRINT:
 push D
 push H
 XCHG
 call gPRINT
 pop H
 pop D
 ret

;g_print_word_f: equ 0x08ed    ; prints a 16-bit number pointed
;by DE to the screen at the current cursor location.
PRHEX:
#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
 push PSW
 RAR
 RAR
 RAR
 RAR
 ani 0FH
 sui 0AH
 jm  prh1
 adi 07H
prh1:
 adi 3AH
 call gPUTC
 pop  PSW
 ani 0FH
 sui 0AH
 jm  prh2
 adi 07H
prh2:
 adi 3AH
 call gPUTC
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
 ret

GETC:
;exx   
;ld (hl),'_' ;Print cursor at location (HL')
 DB 0D9H ; ;exx  Z80 opcodes... :)
 mvi m,05FH
 DB 0D9H ; ;exx  Z80 opcodes... :)
 call gGETC
 ret

IfKeyPress:
 push H
 lxi H,02000h+31 ; test if SPACE is pressed
 mov A,M
; push PSW
; pop PSW
 pop H
 ret
