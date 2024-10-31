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
RUNF2:
  LXI B,1 ; читаю из CAS файла до 0xA5
  LXI H,LINEBUF
  CALL F_READ
  DCX H
  MOV A,M
  CPI 0A5H
  JNZ RUNF2
  LXI B,8 ; читаю из CAS файла 0x55, имя и 0x3C
  CALL F_READ
  cpi 03Ch
  JNZ C_DIRNO ; no CAS file
RUNF4:
  LXI B,1
  CALL F_READ
  CPI 00H
  LXI B,0100h
  JZ  RUNF3 ; размер блока равен 256
  mvi B,0h ; размер блока меньше 256
  mov C,A 
RUNF3:
  push B
  LXI B,2
  CALL F_READ
  LHLD LINEBUF+9 ;Addr for data block store
;  push H
;  mov A,H
;  call PRHEX
;  mov A,L
;  call PRHEX
;  MVI C,','
;  CALL PUTC
;  pop H
  pop B
 push B
 push h
  CALL F_READ
 pop h
 pop B
 push h

 mov A,L
 add H
 pop H
RFLL:
 add M
 inx H
 DCR c
 JNZ RFLL
; call PRHEX
  LXI H,LINEBUF
  LXI B,2 ; читаю из CAS файла CRC и 0x3С или 0x78
  CALL F_READ
; push psw
; LDA LINEBUF
; call PRHEX
; push H
; MVI C,','
; CALL PUTC
; pop H
; pop psw
  CPI 03Ch
  LXI H,LINEBUF+8
  JZ RUNF4
  CPI 078h
  JNZ ERR
  LXI B,2 ; Addr of programm start
  CALL F_READ
  LHLD LINEBUF+8 ;Addr of programm start
;  push H
;  MVI C,','
;  CALL PUTC
;  mov A,H
;  call PRHEX
;  mov A,L
;  call PRHEX
;  pop H
;  ret
  push H
  jmp SD_OFF  ;RUN!

PUTC:   ; prints a character in C to the screen 
 mov A,C
 jmp 033aH
; call 033aH
; ret

PRINT:    ; prints a string pointed by HL
; push PSW
; push B
PR_LOOP:
 mov A,M
 inx H
 ora A
 JZ PREXT
 push H
 call 033ah
 pop H
 jmp PR_LOOP
PREXT:
; pop B
; pop PSW
 ret

;prints a 16-bit number pointed
;by DE to the screen at the current cursor location.
PRHEX:
;#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
 call 033ah
 pop  PSW
 ani 0FH
 sui 0AH
 jm  prh2
 adi 07H
prh2:
 adi 3AH
 call 033ah
;#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
 ret

IfKeyPress:
  push D
  call 02Bh
  pop D
  cpi 20h
  cz IfKE
  mvi A,0ffh
 ret
IfKE:
  push D
  call 02Bh
  pop D
  cpi 00h
  jz IfKE
 ret
