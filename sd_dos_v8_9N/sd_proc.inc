;http://elm-chan.org/docs/mmc/ima/sdinit.png
; command response R1
; 0x00 ok
; or bitfield
; 0x01 idle state
; 0x02 erase reset
; 0x04 illegal command
; 0x08 command crc error
; 0x10 erase sequence error
; 0x20 address error
; 0x40 parameter error
; 0x80 timeout (other bits meaningless)
;
; packet token
; 0xFF none yet
; 0xFE ok
; or bitfield
; 0x01 error
; 0x02 controller error
; 0x04 media ecc failed
; 0x08 out of range
; 0x10 card is locked

CMD0   EQU 040h |  0 ; resets the card
CMD8   EQU 040h |  8 ; read IF_COND
CMD9   EQU 040h |  9 ; read CSD
CMD10  EQU 040h | 10 ; read CID
CMD16  EQU 040h | 16 ; set R/W block
CMD17  EQU 040h | 17 ; read block
CMD24  EQU 040h | 24 ; write block
CMD55  EQU 040h | 55 ; next command is ACMDxx
CMD58  EQU 040h | 58 ; READ_OCR
CMD59  EQU 040h | 59 ; CRC_ON_OFF
ACMD41 EQU 040h | 41 ; send host capacity support, init card

#ifdef SD_n8vem

SD_PWR  EQU 08h ; POWER OFF/ON=0/1 (positive logic)
SD_CS   EQU 04h   ; NPN inverter, positive logic.
SD_CLK  EQU 02h
SD_DOUT EQU 01h
SD_DIN  EQU 80h 

SD_ON:
   MVI A,SD_PWR+SD_CS
   JMP SD_CONF
SD_OFF:
   XRA A
SD_CONF:
  STA SD_DATA_PORT
  RET
SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
  push B
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  mov C,A             ; ld  c, a
  mvi B,8             ; ld  b, 8
  LXI H,SD_DATA_PORT  ; ld  hl, SD_ADDR 
L3:                   ;
  mov A,C             ;-rl  c
  rlc                 ;-
  mov C,A             ;-
  mvi A,6             ; ld  a, 6    ; (SD_PWR+SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ;-djnz  L3
  jnz L3              ;-
  xri SD_CLK          ; xor SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
  pop B
POPHRET:POP H
  RET

SD_GET: PUSH H
  push B
  mvi B,8             ;-ld  d, 8
  LXI H,SD_DATA_PORT  ; ld  hl, SD_ADDR 
L2:
  MOV A,M             ; ld  a, (hl)
  rlc                 ; rla     ; SD_DIN is RTC.7
  mov A,C             ;-rl  e
  ral                 ;-
  mov C,A             ;-
  mvi A, 0Fh          ; ld  a, SD_PWR + SD_CS + SD_DOUT + SD_CLK
  mov M,A             ; ld  (hl), a
  ANI 0Dh             ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a
  dcr B               ;-dec d
  jnz L2              ;-jr  nz, L2
  mov A,C             ;-ld  a, e
  pop B
  POP H
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  RET
#endif ;end #ifdef SD_n8vem

#ifdef GAL_AY_SD_n8vem

SD_AY_PORT EQU 0
AY_PORTA EQU 14
AY_PORTB EQU 15
AY_PORTCMD EQU 7

SD_PWR  EQU 080h   ; POWER OFF/ON=0/1
SD_CS   EQU 040h   
SD_CLK  EQU 020h
SD_DOUT EQU 01h
;SD_DIN  EQU 80h 

SD_ON:
   MVI A,AY_PORTB
   out SD_AY_PORT
   MVI A,SD_PWR
   JMP SD_CONF
SD_OFF:
   MVI A,AY_PORTCMD
   out SD_AY_PORT
   MVI A,(080H+3Fh)         ;portA input, portB output
   out SD_AY_PORT+1
   MVI A,AY_PORTB
   out SD_AY_PORT
   MVI A,SD_CS
SD_CONF:
   out SD_AY_PORT+1
   RET

SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
  push B
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  mov C,A             ; ld  c, a
;  mvi B,8             ; ld  b, 8
;  LXI H,SD_PORTC  ; ld  hl, SD_ADDR 
  MVI A,AY_PORTB
  out SD_AY_PORT
L3:                   ;
;  mov A,C             ;-rl  c
;  rlc                 ;-
;  mov C,A             ;-
;1
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;  dcr B               ;-djnz  L3
;  jnz L3              ;-
;2
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;3
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
 ;4
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;5
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;6
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;7
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge
;8
  DB 0CBh,11h ;rl c
  mvi A,40h ;6        ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; rising clock edge

  xri SD_CLK          ; xor SD_CLK
  out SD_AY_PORT+1 ;  mov M,A    ; ld  (hl), a   ; leave with clock low
  pop B
POPHRET:POP H
  RET

SD_GET: PUSH H
  push B
;  mvi B,8             ;-ld  d, 8
;  LXI H,SD_PORTA  ; ld  hl, SD_ADDR 
L2:
;1
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
;  mov A,C             ;        ;-rl  e
;  ral                 ;-
;  mov C,A             ;-
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;  dcr B               ;        ;-dec d
;  jnz L2              ;        ;-jr  nz, L2
;2
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;3
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;4
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;5
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;6
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;7
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
;8
  MVI A,AY_PORTA
  out SD_AY_PORT
  in SD_AY_PORT+2  ;  MOV A,M  ; ld  a, (hl)
  rlc                 ;        ; rla     ; SD_DIN is RTC.7
  DB 0CBh,11h ;rl c
  MVI A,AY_PORTB
  out SD_AY_PORT
  mvi A,0A1h ;0Fh    ;        ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a
  ANI 81h ;0Dh        ;        ; and NOT SD_CLK
  out SD_AY_PORT+1 ;  mov M,A  ; ld  (hl), a

  mov A,C             ;        ;-ld  a, e
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  pop B
  POP H
  RET
#endif ;end #ifdef GAL_AY_SD_n8vem

#ifdef UT88_WW55_SD_n8vem

SD_PORTA EQU SD_DATA_PORT_WW55+0
;SD_PORTB EQU SD_DATA_PORT_WW55+1
SD_PORTC EQU SD_DATA_PORT_WW55+2
SD_PORTCMD EQU SD_DATA_PORT_WW55+3

SD_PWR  EQU 080h   ; POWER OFF/ON=0/1 (positive logic)
SD_CS   EQU 040h   ; NPN inverter, positive logic.
SD_CLK  EQU 020h
SD_DOUT EQU 01h
;SD_DIN  EQU 80h 

SD_ON:
   MVI A,090H ;mode0, portB,C output, portA input
   out SD_PORTCMD
   MVI A,SD_PWR
   JMP SD_CONF
   nop
SD_OFF:
   MVI A,080H ;mode0, all ports output
   out SD_PORTCMD
   MVI A,SD_CS
SD_CONF:
   out SD_PORTC
   RET
   nop
   nop

SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
  push B
  mov C,A             ; ld  c, a
  mvi B,8             ; ld  b, 8
;  LXI H,SD_PORTC  ; ld  hl, SD_ADDR 
L3:                   ;
  mov A,C             ;-rl  c
  rlc                 ;-
  mov C,A             ;-
  mvi A,40h ;6             ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  out SD_PORTC        ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_PORTC        ; ld  (hl), a   ; rising clock edge
  dcr B               ;-djnz  L3
  jnz L3              ;-
  xri SD_CLK          ; xor SD_CLK
  out SD_PORTC        ; ld  (hl), a   ; leave with clock low
  pop B
POPHRET:POP H
  RET

SD_GET: PUSH H
  push B
  mvi B,8             ;-ld  d, 8
;  LXI H,SD_PORTA  ; ld  hl, SD_ADDR 
L2:
  in SD_PORTA         ; ld  a, (hl)
  rlc                 ; rla     ; SD_DIN is RTC.7
  mov A,C             ;-rl  e
  ral                 ;-
  mov C,A             ;-
  mvi A, 0a1h ;0Fh          ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  out SD_PORTC        ; ld  (hl), a
  ANI 81h ;0Dh             ; and NOT SD_CLK
  out SD_PORTC        ; ld  (hl), a
  dcr B               ;-dec d
  jnz L2              ;-jr  nz, L2
  mov A,C             ;-ld  a, e
  pop B
  POP H
  RET

#endif


#ifdef RK86_WW55_SD_n8vem

SD_PORTA EQU SD_DATA_PORT_WW55+0
SD_PORTC EQU SD_DATA_PORT_WW55+2
SD_PORTCMD EQU SD_DATA_PORT_WW55+3

SD_PWR  EQU 080h   ; POWER OFF/ON=0/1 (positive logic)
SD_CS   EQU 040h   ; NPN inverter, positive logic.
SD_CLK  EQU 020h
SD_DOUT EQU 01h
;SD_DIN  EQU 80h 

SD_ON:
   MVI A,090H ;mode0, portB,C output, portA input
   STA SD_PORTCMD
   MVI A,SD_PWR
   JMP SD_CONF
SD_OFF:
   MVI A,080H ;mode0, all ports output
   STA SD_PORTCMD
   MVI A,SD_CS
SD_CONF:
   STA SD_PORTC
   RET

SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
  push B
  mov C,A             ; ld  c, a
  mvi B,8             ; ld  b, 8
  LXI H,SD_PORTC  ; ld  hl, SD_ADDR 
L3:                   ;
  mov A,C             ;-rl  c
  rlc                 ;-
  mov C,A             ;-
  mvi A,40h ;6             ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ;-djnz  L3
  jnz L3              ;-
  xri SD_CLK          ; xor SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
  pop B
POPHRET:POP H
  RET

SD_GET: PUSH H
  push B
  mvi B,8             ;-ld  d, 8
  LXI H,SD_PORTA  ; ld  hl, SD_ADDR 
L2:
  MOV A,M             ; ld  a, (hl)
  rlc                 ; rla     ; SD_DIN is RTC.7
  mov A,C             ;-rl  e
  ral                 ;-
  mov C,A             ;-
  mvi A, 0a1h ;0Fh          ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  inr l
  inr l
  mov M,A             ; ld  (hl), a
  ANI 81h ;0Dh             ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a
  dcr l
  dcr l
  dcr B               ;-dec d
  jnz L2              ;-jr  nz, L2
  mov A,C             ;-ld  a, e
  pop B
  POP H
  RET
#endif ;end #ifdef RK86_WW55_SD_n8vem

#ifdef STD_WW55_SD_n8vem

SD_PORTA EQU SD_DATA_PORT_WW55+0
SD_PORTC EQU SD_DATA_PORT_WW55+2
SD_PORTCMD EQU SD_DATA_PORT_WW55+3

SD_PWR  EQU 080h   ; POWER OFF/ON=0/1 (positive logic)
SD_CS   EQU 040h   ; NPN inverter, positive logic.
SD_CLK  EQU 020h
SD_DOUT EQU 01h
;SD_DIN  EQU 80h 

SD_ON:
   MVI A,090H ;mode0, portB,C output, portA input
   STA SD_PORTCMD
   MVI A,SD_PWR
   JMP SD_CONF
SD_OFF:
   MVI A,080H ;mode0, all ports output
   STA SD_PORTCMD
   MVI A,SD_CS
SD_CONF:
   STA SD_PORTC
   RET

SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
  push B
  mov C,A             ; ld  c, a
  mvi B,8             ; ld  b, 8
  LXI H,SD_PORTC  ; ld  hl, SD_ADDR 
L3:                   ;
  mov A,C             ;-rl  c
  rlc                 ;-
  mov C,A             ;-
  mvi A,40h ;6             ; ld  a, 6    ; (SD_PWR+/SD_CS)/2    
  ral                 ; rla     ; SD_DOUT is RTC.0
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ;-djnz  L3
  jnz L3              ;-
  xri SD_CLK          ; xor SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
  pop B
POPHRET:POP H
  RET

SD_GET: PUSH H
  push B
  mvi B,8             ;-ld  d, 8
  LXI H,SD_PORTA  ; ld  hl, SD_ADDR 
L2:
  MOV A,M             ; ld  a, (hl)
  rlc                 ; rla     ; SD_DIN is RTC.7
  mov A,C             ;-rl  e
  ral                 ;-
  mov C,A             ;-
  mvi A, 0a1h ;0Fh          ; ld  a, SD_PWR + /SD_CS + SD_DOUT + SD_CLK
  inr l
  inr l
  mov M,A             ; ld  (hl), a
  ANI 81h ;0Dh             ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a
  dcr l
  dcr l
  dcr B               ;-dec d
  jnz L2              ;-jr  nz, L2
  mov A,C             ;-ld  a, e
  pop B
  POP H
  RET
#endif ;end #ifdef STD_WW55_SD_n8vem

#ifdef SD_msx
SD_ON:  
  DB 3Eh ; <- MVI A,0AFh
SD_OFF:
  XRA A        ; <- 0AFh
  STA SD_CONF_PORT
SD_FIN: MVI A,0FFh
SD_PUT: PUSH H
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  LXI H,SD_DATA_PORT
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
  RLC
  MOV M,A
POPHRET:POP H
  RET

SD_GET: PUSH H
  LXI H,SD_DATA_PORT
  MVI A,0FFh
  MOV M,A
  MOV M,A
  MOV M,A
  MOV M,A
  MOV M,A
  MOV M,A
  MOV M,A
  MOV M,A
  MOV A,M
  POP H
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  RET

#endif ;end #ifdef SD_msx


#ifdef RK86_WW55_SD_HWM_PVV

#define SD_CS 32 ;0x20h
#define SD_WR 16 ;0x10h
#define SD_A0  8 ;0x08h

SD_ON:
   MVI A,090H ;mode0, portB,C output, portA input
   STA SD_DATA_PORT_WW55+3 ;0a003H
   MVI A,10h
   JMP SD_CONF
SD_OFF:
   MVI A,080H ;mode0, all ports output
   STA SD_DATA_PORT_WW55+3 ;0a003H
   MVI A,080H|SD_WR ;0F8h ; 0b10000000 CS_ROM=1, 0, CS_SD=0, WR=1
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   MVI A,00h
SD_CONF:
   STA SD_DATA_PORT_WW55+1 ;0a001H ;SD_DATA_PORT
   MVI A,080H|SD_CS|SD_A0 ;0F8h ;098h ; 0b10011000 CS_ROM=1, 0, CS_SD=1, WR=0, SD_A0=1
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   MVI A,080H|SD_WR|SD_A0 ;0F0h ; 0b11110000 CS_ROM=1, 0, CS_SD=0, WR=1 
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   RET
SD_FIN: MVI A,0FFh
SD_PUT:
   STA SD_DATA_PORT_WW55+1 ;0a001H ;SD_DATA_PORT
   MVI A,080H|SD_CS ;090h ; 0b10010000 CS_ROM=1, 0, CS_SD=1, WR=0
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   MVI A,080H|SD_WR ;0F0h ; 0b11110000 CS_ROM=1, 0, CS_SD=0, WR=1 
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
   RET
POPHRET:POP H
  RET

SD_GET:
   CALL SD_FIN
   MVI A,080H|SD_CS|SD_WR ;0B0h ; 0b10110000 CS_ROM=1, 0, CS_SD=1, WR=1
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   LDA SD_DATA_PORT_WW55 ;0a000H ;SD_DATA_PORT
   push PSW
   MVI A,080H|SD_WR ;0F0h ; 0b11110000 CS_ROM=1, 0, CS_SD=0, WR=1 
   STA SD_DATA_PORT_WW55+2 ;0a002H ;SD_CONF_PORT
   pop PSW
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  RET
#endif ;end #ifdef RK86_WW55_SD_HWM_PVV


#ifdef SD_HWM_PVV

SD_ON:
   MVI A,0Fh
   JMP SD_CONF
SD_OFF:
   MVI A,0ch
SD_CONF:
   STA SD_CONF_PORT
   RET
SD_FIN: MVI A,0FFh
SD_PUT:
   STA SD_DATA_PORT
   NOP
#ifdef MX2
WaitSPI_1:
      LDA SD_CONF_PORT
      ANI 040h
      JNZ WaitSPI_1    ; ждЄм окончани€ сигнала BUSY
#else
   NOP
#endif
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
   RET
POPHRET:POP H
  RET

SD_GET:
   CALL SD_FIN
#ifdef MX2
WaitSPI:
      LDA SD_CONF_PORT
      ANI 040h
      JNZ WaitSPI    ; ждЄм окончани€ сигнала BUSY
#else
   NOP
   NOP
#endif
   LDA SD_DATA_PORT
 ;===========================
;  push psw
;  call PRHEX
;  pop psw
 ;===========================
  RET
#endif ;end #ifdef SD_HWM_PVV


SD_CMD: LXI H,0
SD_CMDW:LXI D,0
SD_CMDD:CALL SD_FIN
  MOV A,C
  push psw
  CALL SD_PUT
  MOV A,D
  CALL SD_PUT
  MOV A,E
  CALL SD_PUT
  MOV A,H
  CALL SD_PUT
  MOV A,L
  CALL SD_PUT
  pop psw
  cpi CMD8
  mvi A,87h
  jz putCRC
  MVI A,95h
putCRC:
  CALL SD_PUT
  LXI D,8080h
SD_WAIT:LXI H,20000
SDW_L1: CALL SD_GET
  MOV C,A    ; ld    C,A
  SUB D      ; sub   D 
  CMP E      ; cp    E
  MOV A,C    ; ld    A,C
  RNC        ; ret   nc 
  DCX H      ; dec   hl
  MOV A,H    ; ld    A,H
  ORA L      ; or    L
  JNZ SDW_L1 ; jp    nz,SDW_L1
  SUI 1      ; sub   1
  RET
       
SD_INIT:
#ifdef UT88_WW55_SD_n8vem
  CALL SD_OFF
  MVI B,0f0h
;  LXI H,SD_PORTC  ; ld  hl, SD_ADDR 
LI3:                  ;
  mvi A,SD_PWR+SD_CS+SD_DOUT
  out SD_PORTC        ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  out SD_PORTC        ; ld  (hl), a   ; rising clock edge
  dcr B               ; djnz  L3
  jnz LI3
  xri SD_CLK          ; xor SD_CLK    ; and NOT SD_CLK
  out SD_PORTC        ; ld  (hl), a   ; leave with clock low
#endif

#ifdef GAL_AY_SD_n8vem
  CALL SD_OFF
  MVI B,0f0h
  MVI A,AY_PORTB
  out SD_AY_PORT
LI3:                  ;
  mvi A,SD_PWR+SD_CS+SD_DOUT
  out SD_AY_PORT+1    ;  mov M,A      ; ld  (hl), a   ; clock is low
  ori SD_CLK          ;               ; or  SD_CLK
  out SD_AY_PORT+1    ;  mov M,A      ; ld  (hl), a   ; rising clock edge
  dcr B               ;               ; djnz  L3
  jnz LI3
  xri SD_CLK          ; xor SD_CLK    ; and NOT SD_CLK
  out SD_AY_PORT+1    ;  mov M,A      ; ld  (hl), a   ; leave with clock low
#endif

#ifdef RK86_WW55_SD_n8vem
  CALL SD_OFF
  MVI B,80h
  LXI H,SD_PORTC      ; ld  hl, SD_ADDR 
LI3:                  ;
  mvi A,SD_PWR+SD_CS+SD_DOUT
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ; djnz  L3
  jnz LI3
  xri SD_CLK          ; xor SD_CLK    ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
#endif

#ifdef STD_WW55_SD_n8vem
  CALL SD_OFF
  MVI B,80h
  LXI H,SD_PORTC      ; ld  hl, SD_ADDR 
LI3:                  ;
  mvi A,SD_PWR+SD_CS+SD_DOUT
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ; djnz  L3
  jnz LI3
  xri SD_CLK          ; xor SD_CLK    ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
#endif

#ifdef SD_n8vem
  MVI B,80h
  LXI H,SD_DATA_PORT  ; ld  hl, SD_ADDR 
LI3:                  ;
  mvi A,SD_PWR
  mov M,A             ; ld  (hl), a   ; clock is low
  ori SD_CLK          ; or  SD_CLK
  mov M,A             ; ld  (hl), a   ; rising clock edge
  dcr B               ; djnz  L3
  jnz LI3
  xri SD_CLK          ; xor SD_CLK    ; and NOT SD_CLK
  mov M,A             ; ld  (hl), a   ; leave with clock low
#endif

#ifdef SD_msx
  CALL SD_OFF
  MVI B,10h
  CALL SD_FIN
  DCR B
  JNZ $-4
#endif

#ifdef SD_HWM_PVV
  CALL SD_OFF
  MVI B,10h
  CALL SD_FIN
  DCR B
  JNZ $-4
#endif

#ifdef SD_RK86_WW55_SD_HWM_PVV
  CALL SD_OFF
  MVI B,10h
  CALL SD_FIN
  DCR B
  JNZ $-4
#endif

  CALL SD_ON
  MVI C,CMD0
  CALL SD_CMD
  CPI 1
  RNZ
  LXI H,01AAh
  MVI C,CMD8
  CALL SD_CMDW
  CPI 01h
  jz SD_V2
SD_V1:
  MVI C,041h
  CALL SD_CMD
  ANI 0FEh     ; and   #FE
  RNZ          ; ret   nz
  MVI C,041h
  CALL SD_CMD
  CPI 1       ; cp    1
  jz SD_V1
;=============================================
#ifdef SD_DBG_PRINT1
  push PSW
  LXI H,SD_0
  CALL PRINT
  pop PSW
#endif
;=============================================
  ora A
  ret
SD_V2:
  call SD_GET  ;read cmd8 answer
  call SD_GET
  call SD_GET
  call SD_GET
  CPI 0AAh
  jnz SD_V1 ;if here, answer must be (0x01,0x00,0x00,0x01,0xAA) if not check SD_V1
SDI_L1:
  MVI C,CMD55
  CALL SD_CMD
  ANI 0FEh     ; and   #FE
  RNZ          ; ret   nz
  LXI H,0000h
  LXI D,4000h
  MVI C,ACMD41 ; ld    C,ACMD41
  CALL SD_CMDD
  CPI 1       ; cp    1
  JZ SDI_L1   ; jp    z,SDI_L1
  MVI C,CMD58
  CALL SD_CMD
  CALL SD_GET
  ANI 040h       ; cp
  jnz SD_V2P
;=============================================
#ifdef SD_DBG_PRINT1
  push H
  LXI H,SD_1
  CALL PRINT
  pop H
#endif
;=============================================
  CALL SD_GET
  CALL SD_GET
  CALL SD_GET
SD_V2M:
  LXI H,0200h
  MVI C,CMD16
  CALL SD_CMDW
  ORA A       ; or    A
  RET
SD_V2P:
  CALL SD_GET
  CALL SD_GET
  CALL SD_GET
;=============================================
#ifdef SD_DBG_PRINT1
  push H
  LXI H,SD_2
  CALL PRINT
  pop H
#endif
;=============================================
  mvi A,0ffh
  STA SDTYPE

  LXI H,0200h
  MVI C,CMD16
  CALL SD_CMDW
  ORA A       ; or    A
  RET

#ifdef SD_DBG_PRINT1
SD_0: DB "SDV1",0DH,0ah,0
SD_1: DB "SDV2",0DH,0ah,0
SD_2: DB "SDV2+",0DH,0ah,0
#endif

SD_RWR:
  PUSH D
  PUSH B
  LXI D,0FFh
  CALL SD_WAIT
  POP B
  POP H
  RC  ;  JC POPHRET
  LDA SDTYPE
  CPI 00h
  JZ SD_RWR0
  mov E,C
  MVI D,0 ;SDHC...
  stc
  cmc
  ret
SD_RWR0:
  MOV A,C
  DAD H
  ADC A
  MOV D,A
  MOV E,H
  MOV H,L
  MVI L,0
  RET

SD_READ:
  PUSH H
  call SD_RWR
  JC POPHRET
  MVI C,CMD17
  CALL SD_CMDD
  JC POPHRET
  LXI D,0FF01h
  CALL SD_WAIT
  POP H
  CPI 0FEh
  RNZ
  MVI B,0
SDR_L1: CALL SD_GET
  MOV M,A
  INX H
  CALL SD_GET
  MOV M,A
  INX H
  DCR B
  JNZ SDR_L1
#ifndef SD_msx
  CALL SD_FIN ; добиваем еще два пустых байта CRC - new in 8.6
  CALL SD_FIN
#else
  CALL SD_GET
  CALL SD_GET
#endif
  RET

#ifdef RWR ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
SD_WRITE:
  PUSH H
  call SD_RWR
  JC POPHRET
  MVI C,CMD24 ;запись блока в 512 байт
  CALL SD_CMDD
  JC POPHRET
  POP H
  MVI A,0FEh ; отправл€ем подтверждение
  CALL SD_PUT
  MVI B,0
SDR_WL1: ;отправл€ем 512 байт
  MOV A,M
  INX H
  CALL SD_PUT
  MOV A,M
  INX H
  CALL SD_PUT
  DCR B
  JNZ SDR_WL1
#ifndef SD_msx
  CALL SD_FIN ; добиваем еще два пустых байта
  CALL SD_FIN
#else
  XRA A
  CALL SD_PUT ; добиваем еще два пустых байта
  CALL SD_PUT
#endif
#ifdef SD_msx
  ora A
#endif
#ifdef SD_n8vem
  ora A
#endif
#ifdef RK86_WW55_SD_n8vem
  ora A
#endif
#ifdef STD_WW55_SD_n8vem
  ora A
#endif
#ifdef GAL_AY_SD_n8vem
  ora A
#endif
  RET
#endif ;!!!!!!!!!!!!!!!!!!!!!!!!!!!
