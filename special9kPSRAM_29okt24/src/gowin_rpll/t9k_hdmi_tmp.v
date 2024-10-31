//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.11
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Oct 27 18:46:26 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    t9k_hdmi your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkoutd3(clkoutd3_o), //output clkoutd3
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
