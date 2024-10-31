//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.01 (64-bit)
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Wed Oct 16 13:48:45 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    t9k_vmem your_instance_name(
        .dout(dout), //output [10:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [13:0] ada
        .din(din), //input [10:0] din
        .adb(adb) //input [13:0] adb
    );

//--------Copy end-------------------
