@echo off
del sdos.bin
del sdos.h
tasm.exe -85 -b dos_rk.asm sdos.bin dos_rk.lst
rem copy hd.bin /b + SDOS.BIN /b SDOS.ORI /b
rem copy RKO_hd.bin /b + SDOS.BIN /b SDOS.RKO /b
bin2header.exe sdos.bin
ren sdos.bin.h sdos.h
