#define ORG .org
#define EQU .equ
#define DB  .db
#define DW  .dw

#define SDOS_VER "SDOS_V8.9N"

#define SD_DBG_PRINT0
#define SD_DBG_PRINT1
#define SD_DBG_PRINT2

;#define SD_msx
#define SD_HWM_PVV
;#define RK86_WW55_SD_HWM_PVV
;#define STD_WW55_SD_n8vem    ; Specialist
;#define RK86_WW55_SD_n8vem    ; APOGEE and RK86 memmap
;#define UT88_WW55_SD_n8vem    ; ports IN - OUT
;#define GAL_AY_SD_n8vem
;#define SD_n8vem
;#define FAT12_ON
#define FAT16_ON
;#define RWR
;#define UT88
;#define APOGEE
;#define RK86
#define STD
;#define MX2
;#define GAL
;#define ORION
;#define TRS80

;==========================================================
#ifdef TRS80  ; TRS-80 and clones - SD
GETC  EQU 00384H ;
;PUTC  EQU 033AH ; input in A :(, but not in C
#ifdef SD_HWM_PVV
SD_DATA_PORT EQU 03bfeh ;0C800H
SD_CONF_PORT EQU SD_DATA_PORT+1
#endif
START_ADDR   EQU 0f000h ;03000h
BUF     EQU 0e800h ;0c000h
#endif
;==========================================================

#ifdef GAL  ; Galaxy - SD
gGETC  EQU 00cf5H ;
gPUTC  EQU 00020H
gPRINT EQU 00937H
#ifdef SD_n8vem
SD_DATA_PORT EQU 0C800H
#endif
#ifdef SD_msx
SD_DATA_PORT EQU 0C801H
SD_CONF_PORT EQU SD_DATA_PORT-1
#endif
#ifdef SD_HWM_PVV
SD_DATA_PORT EQU 0C800H
SD_CONF_PORT EQU SD_DATA_PORT+1
#endif
START_ADDR   EQU 07000h ;0F000h
BUF     EQU 0c000h
#endif
;==========================================================

#ifdef MX2  ; MX - SD_MX2
GETC  EQU 0f803H
PUTC  EQU 0f809H
PRINT EQU 0f818H
PRHEX EQU 0f815H
IfKeyPress EQU 0F81BH
SD_DATA_PORT EQU 0fff0H ;U4
SD_CONF_PORT EQU SD_DATA_PORT+1 
START_ADDR   EQU 0D400H ;08000H
BUF     EQU 0E000H ;08800H
#endif
;==========================================================

#ifdef STD  ; STD - SD_MX2
GETC  EQU 0C803H
PUTC  EQU 0C809H
PRINT EQU 0C818H
PRHEX EQU 0C815H
IfKeyPress EQU 0C81BH
#ifdef SD_msx
SD_DATA_PORT EQU 0f701H
SD_CONF_PORT EQU SD_DATA_PORT-1
#endif
#ifdef SD_HWM_PVV
SD_DATA_PORT EQU 0F000H ;0f700H
SD_CONF_PORT EQU SD_DATA_PORT+1
#endif
#ifdef STD_WW55_SD_n8vem
SD_DATA_PORT_WW55 EQU 0F000h
#endif
START_ADDR   EQU 0D000H
;BUF     EQU 0E000h	; ÂÈ53 addr
;BUF     EQU 0D800h
BUF     EQU 0D900h	; + 100h for sdos binary more than 2048 bytes, now 2304 bytes possible
#endif
;==========================================================

#ifdef RK86
GETC  EQU 0F803H
PUTC  EQU 0F809H
PRINT EQU 0F818H
PRHEX EQU 0F815H
IfKeyPress EQU 0F81BH
SD_DATA_PORT EQU 0d000H
SD_CONF_PORT EQU SD_DATA_PORT+1
SD_DATA_PORT_WW55 EQU 0a000H
#define SD_ROM
#ifdef SD_ROM
START_ADDR   EQU 06000H
#else
START_ADDR   EQU 0f000H
#endif
BUF     EQU 06900h
#endif
;==========================================================

#ifdef APOGEE
GETC  EQU 0F803H
PUTC  EQU 0F809H
PRINT EQU 0F818H
PRHEX EQU 0F815H
IfKeyPress EQU 0F81BH
SD_DATA_PORT_WW55 EQU 0ee00h
START_ADDR   EQU 0d000H
BUF     EQU 0d900h
#endif
;==========================================================

#ifdef UT88
GETC  EQU 0F803H
PUTC  EQU 0F809H
PRINT EQU 0F818H
PRHEX EQU 0F815H
IfKeyPress EQU 0F81BH
SD_DATA_PORT_WW55 EQU 0F8H
START_ADDR   EQU 0d000H
BUF     EQU 0d900h
#endif
;==========================================================

#ifdef ORION
GETC  EQU 0F803H
PUTC  EQU 0F809H
PRINT EQU 0F818H
PRHEX EQU 0F815H
IfKeyPress EQU 0F81BH
#ifdef SD_n8vem
SD_DATA_PORT EQU 0f762H
#endif
#ifdef SD_msx
SD_DATA_PORT EQU 0f763H
SD_CONF_PORT EQU SD_DATA_PORT-1
#endif
#ifdef SD_HWM_PVV
SD_DATA_PORT EQU 0f762H
SD_CONF_PORT EQU SD_DATA_PORT+1
#endif
;START_ADDR   EQU 09600H ;RKO
;BUF     EQU 0a100h
START_ADDR   EQU 0a680H ;ORI
BUF     EQU 0b100h
#endif
;==========================================================

BUFDIR  EQU BUF+0200h
CWD     EQU BUF+0400H
FATSEC  EQU BUF+0500H

ROOTSEC EQU FATSEC+4
DATASEC EQU ROOTSEC+4
ROOTLEN EQU DATASEC+4
ROOTLNS EQU ROOTLEN+2
SECINBL EQU ROOTLNS+2
FAT_NXT EQU SECINBL+1
BUFSEC  EQU FAT_NXT+3
BLKLEN  EQU BUFSEC+4
BLKSEC  EQU BLKLEN+1
BNEXT   EQU BLKSEC+4
FBPOS   EQU BNEXT+4
FBLEN   EQU FBPOS+2
DIRREC  EQU FBLEN+2
CWDBLK  EQU DIRREC+1
LINEBUF EQU CWDBLK+4
SDTYPE  EQU LINEBUF+38h
