del rom.bin
copy /b c000_loader.rom + c800_monitor.rom + sdos.bin rom.bin
srec_cat.exe -generate 0x1ff0 0x2000 -constant-l-e 0x0 4 rom.bin -binary -o rom_b.bin -binary	
bin2mi.exe rom.bin rom.mi