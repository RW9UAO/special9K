#include "defs.inc"
  ORG START_ADDR
; 0xCB7F  => BC=crc

;CALL FS_FNDF ; DE - name of file for finding, out HL - string FAT record of file
;CALL F_OPEN ; DE - name of file for opening, out C==1 if file not founded
;CALL F_READ ; HL - addr for store readed data, BC - size of readed data
;#ifdef GAL
;  ORG START_ADDR-10
;  DB 0,0,0,0,0
;  DB 0A5h
;  DB 00,70h,0ffh,7fh
;#endif

#ifdef RK86
#ifdef SD_ROM
#else
  jmp 0f800H
  nop
#endif
#endif

ENTRY:
#ifdef TRS80
  call 001c9H  ; полное стирание экрана
  mvi a,20h
  STA 4022h
#endif
#ifdef MX2
  call 0c84eH  ; полное стирание экрана
#endif
#ifdef ORION
  mvi A,01fh
  call 0f80fh ;clear screen
#endif
;#ifdef STD
;  ORG START_ADDR-4
;  DB 00,0d0h,0d0h,0d8h
;  LXI SP,0F6CFH
;#endif
;=============================================
#ifdef SD_DBG_PRINT0
  LXI H,TSD_INIT
  CALL PRINT
#endif
;=============================================
  lxi h,BUF
  lxi b,2048-256
clrmem:
  mvi m,0
  inx h
  dcx b
  mov a,c
  ora b
  jnz clrmem
  CALL FS_RST
LOOP: 
  MVI C,38H
  LXI H,LINEBUF
LOOP0:
  mvi m,0
  inx h
  DCR C
  JNZ LOOP0
  LXI H,A_DRIVE
  CALL PRINT
  LXI H,CWD
  CALL PRINT
  MVI C,'>'
  CALL PUTC
  CALL READLN
  LXI H,LOOP
  PUSH H
  LXI H,CMDLST
LOOP1:  MOV A,M
  ORA A
  JZ RUNFILE
  LXI D,LINEBUF
LOOP2:  MOV A,M
  ORA A
  JZ LOOP3
  LDAX D
  CMP M
  JNZ LOOP4
  INX D
  INX H
  JMP LOOP2
LOOP3:  LDAX D
  ORA A
  JZ LOOP5
  CPI 20H
  JZ LOOP5
LOOP4:  MOV A,M
  INX H
  ORA A
  JNZ LOOP4
  INX H
  INX H
  JMP LOOP1
LOOP5:  INX H
  MOV E,M
  INX H
  MOV D,M
#ifdef GAL
  call 02edH
#else
  CALL PRINT_NEWLINE
#endif
  XCHG
  PCHL

PRINTN: MOV C,M
  INX H
  CALL PUTC
  DCR B
  JNZ PRINTN
  RET

#ifdef SD_DBG_PRINT0
TSD_INIT: DB SDOS_VER,0dh,0ah,0
#endif

C_DIR:
  LXI D,LINEBUF+2
  INX D
  LDAX D
  CPI 20H
  JZ $-4
  ORA A
  JNZ $+6
  LXI D,ALLFILS
  CALL FS_FNDF
  JC C_DIRNO
C_DIR1: PUSH H
  CALL IfKeyPress ; опрос нажатия кнопок 
  CPI 0FFH    ; приостановка вывода списка файлов если есть нажатие любой кнопки
  JNZ $-5
  LXI B,11
  DAD B
  MOV A,M
  POP H
  ANI 8
  JNZ C_DIR2
  MVI B,8
  CALL PRINTN
  MVI C,' '
  CALL PUTC
  MVI B,3
  CALL PRINTN
  MVI C,' '
  CALL PUTC
  mov A,M
  ani 010H
  jz C_DIR11
  LXI H,NODIR+4 ;_DIR
  CALL PRINT
  jmp C_DIR12
C_DIR11:
  mov A,L
  adi 012H
  mov L,A
  mov A,M
  call PRHEX
  dcx H
  mov A,M
  call PRHEX
C_DIR12:
  CALL PRINT_NEWLINE
C_DIR2: CALL FS_FNDN
  JNC C_DIR1
  RET
C_DIRNO_POPH:
  pop H
C_DIRNO:LXI H,NOFILES
  JMP PRINT

C_CD: LXI H,LINEBUF+1
  INX H
  MOV A,M
  CPI 20H
  JZ $-4
  ORA A
  JNZ C_CD1
  CALL PRINT_NEWLINE
  LXI H,CWD
  JMP PRINT
C_CD1:  XCHG
  CALL FS_CHDIR
  RNC
  LXI H,NODIR
  JMP PRINT

C_I: 
  CALL SD_OFF
  pop H
  JMP START_ADDR

C_X: 
  CALL SD_OFF
#ifdef MX2
  JMP 0F800H
#endif
#ifdef STD
  JMP 0C000H
#endif
#ifdef APOGEE
  JMP 0F800H
#endif
#ifdef RK86
  JMP 0F800H
#endif
#ifdef UT88
  JMP 0F800H
#endif
#ifdef GAL
  pop D ;garbage read
  ret   ;return to promt
#endif
#ifdef TRS80
  pop D ;garbage read
  LXI B,01a18H
  jmp 019AEh
;  ret   ;return to promt
#endif

#ifdef ORION
  JMP 0F800H
#endif

#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
C_RWR: 
  LXI D,LINEBUF+2
  CALL F_OPEN
  JC C_DIRNO ; no file
  LXI H,LINEBUF+2
C_RWR1: 
  MOV A,M
  CPI 0
  JZ C_RWR2
  CPI 2CH
  INX H
  JNZ C_RWR1
C_RWR2: 
  CALL R65
  LXI H,ERR
  JC PRINT
  LHLD LINEBUF+26  ;size области
  MOV  C,L  ;
  MOV  B,H  ;
  LHLD LINEBUF+24  ;АДРЕС  начала области
  LXI D,LINEBUF
  LDAX D
  CPI 'R'
  JZ C_RWR3
  CALL F_WRITE
  JMP C_RWR4
C_RWR3: 
  CALL F_READ
C_RWR4: 
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
  LXI H,RWR_OK
  JMP PRINT

#ifdef ORION
#include "dos_orion_RUNF.inc"
#endif

#ifdef MX2
#include "dos_mx_RUNF.inc"
#endif

#ifdef STD
#include "dos_std_RUNF.inc"
#endif

#ifdef GAL
#include "dos_gal_RUNF.inc"
#endif

#ifdef TRS80
#include "dos_trs_RUNF.inc"
#endif

#ifdef APOGEE
#include "dos_rk_RUNF.inc"
#endif

#ifdef RK86
#include "dos_rk_RUNF.inc"
#endif

#ifdef UT88
#include "dos_rk_RUNF.inc"
#endif

READLN: LXI H,LINEBUF
READL1:
 CALL GETC
  CPI 8
  JZ READL3
  CPI 5FH
  JZ READL3
  CPI 18H
  JZ READL4
  MVI M,0
  CPI 0DH
  RZ
#ifdef GAL
  CPI 1DH       
  JNZ READL5    
  DCX H         
  JMP READL2    
READL5:
#endif
  MOV M,A
  INX H
READL2: MOV C,A
  CALL PUTC
  JMP READL1
READL3: MOV A,L
  CPI LINEBUF & 255
  JZ READL1
  MVI C,8
  CALL PUTC
  MVI C,20H
  CALL PUTC
  MVI C,8
  CALL PUTC
  DCX H
  JMP READL1
READL4: MOV A,M
  ORA A
  JZ READL1
  CPI 0DH
  JZ READL1
  INX H
  JMP READL2
;**********************************************
#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!

SET_LAST_SPACE:
  INX D
  push D
  mvi c,0AH
R66:
  LDAX D
  CPI 0
  JNZ R68
  MVI A,20H
  STAX D
  JMP R67
R68:
  INX D
  DCR C
  JNZ R66
R67:
  pop D
  ret
;**********************************************
;Подпрограмма ввода адресов для функции
;**********************************************
R65:
  XCHG
#ifdef MX2
  call SET_LAST_SPACE
  call 0c839H ; получить из строки в DE шестнадцатеричный код, помещенный в HL
  shld LINEBUF+24
  RC
  call 0c839H ; получить из строки в DE шестнадцатеричный код, помещенный в HL
  shld LINEBUF+26
  RC
  ret
#else
  LXI  H,0
  shld LINEBUF+24
  shld LINEBUF+26
  CALL R7C 
  shld LINEBUF+24
  RC
  CALL R7C 
  shld LINEBUF+26
;  RC
  ret
;*********************************************
;Подпрограмма ввода одного 16 адреса
;*********************************************
R7C:  
      LXI  H,0 
      MVI  B,0
R7F:  
      LDAX D
      INX  D
      CPI  00H
      JZ   R7E 
      CPI  2CH
      RZ
      CPI  20H
      JZ   R7F 
      SUI  30H
      JM   R79 
      CPI  0AH
      JM   R80 
      CPI  11H
      JM   R79 
      CPI  17H
      JP   R79 
      SUI  07H
R80:
      MOV  C,A
      DAD  H
      DAD  H
      DAD  H
      DAD  H
      JC   R79 
      DAD  B
      JMP  R7F 
R79:
  STC
R7E:
      RET
#endif
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!

;*********************************************
PRINT_NEWLINE:
  LXI H,NEWLINE
  CALL PRINT
  RET

#ifdef TRS80
NEWLINE:DB 0DH,0
#else
NEWLINE:DB 0DH,0AH,0
#endif

#ifdef GAL
A_DRIVE:DB "A:",0
NOFILES:DB "NO FILE(S)",0DH,0
#else
#ifdef TRS80
A_DRIVE:DB "A:",0
NOFILES:DB "NO FILE(S)",0DH,0
#else
A_DRIVE:DB 0DH,0AH,"A:",0
NOFILES:DB "NO FILE(S)",0
#endif
#endif

RWR_OK: DB "OK",0DH,0
ERR:    DB "ERR",0DH,0
ALLFILS:DB "*",0

#ifdef STD
DOTRK:  DB ".RKS",0
#endif

#ifdef MX2
DOTRK:  DB ".RKX",0
DOTRKS: DB ".RKS",0
M2MON:  DB "M2_C000.MON",0
#endif

#ifdef APOGEE
DOTRK:  DB ".RKA",0
#endif

#ifdef RK86
DOTRK:  DB ".RKR",0
#endif

#ifdef UT88
DOTRK:  DB ".RKU",0
#endif

#ifdef GAL
DOTRK:  DB ".GTP",0
#endif

#ifdef TRS80
DOTRK:  DB ".CAS",0
#endif


#ifdef ORION
DOTRK:  DB 024h,".RKO",0
#endif

NODIR:  DB 0DH,"NO " 
CMDLST: DB "DIR",0
        DW C_DIR
        DB "CD",0
        DW C_CD
        DB "X",0
        DW C_X
#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DB "R",0
        DW C_RWR
        DB "W",0
        DW C_RWR
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DB "I",0
        DW C_I
#ifdef GAL
        DB "WB",0
        DW C_WB
#endif
#ifdef ORION
        DB "L",0
        DW C_LRD
        DB "S",0
        DW C_SRD
#endif
#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
#ifdef MX2
        DB "L",0
        DW C_LRD
        DB "S",0
        DW C_SRD
#endif
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
        DB 0

#include "sd_proc.inc"
#include "fs_proc.inc"

#ifdef UT88
ORG START_ADDR+0fffh
    nop
#endif

#ifdef APOGEE
ORG START_ADDR+0fffh
    nop
#endif

#ifdef RK86
ORG START_ADDR+0fffh
    nop
#endif

#ifdef GAL
ORG START_ADDR+0fffh
    nop
#endif

#ifdef ORION
ORG START_ADDR+0a7fh
;ORG 0a0ffh
;ORG 0b0ffh
 nop
;ORG 0bffdh
; jmp 0b800h
#endif
;ORG 0dbffh
; nop

  .end
