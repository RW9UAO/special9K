//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.01 (64-bit) 
//Created Time: 2024-10-23 23:34:06
create_clock -name clk_pixel -period 37.037 -waveform {0 18.518} [get_nets {clk_pixel}]
create_clock -name clkinput -period 37.037 -waveform {0 18.518} [get_ports {clkinput}]
create_clock -name clk200mhz -period 5 -waveform {0 2.5} [get_nets {clk200mhz}]
create_clock -name clkB32mhz -period 31.25 -waveform {0 15.625} [get_nets {clkB32mhz}]
create_clock -name cpu_clk -period 500 -waveform {0 250} [get_nets {cpu_div[3]}]
