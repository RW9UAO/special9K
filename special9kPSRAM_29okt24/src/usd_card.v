module sdos(
    input reset,
    input c_sclk, // 2 mhz
    input [15:0]cpu_ADDR,
    input [7:0]o_cpu_data,
    input cpu_nWR,
    output [7:0] sd_o,

    input	wire SD_DAT,					//	SD Card Data
    output	wire SD_DAT3,				//	SD Card Data 3
    output	wire SD_CMD,					//	SD Card Command Signal
    output	wire SD_CLK					//	SD Card Clock
);

reg sdcs;
reg sdclk;
reg sdcmd;
reg [4:0]spi_cnt;
reg [7:0]spi_shift;
////wire[7:0] sd_o = {sddata, SD_DAT};    //  SD_MSX
assign sd_o = spi_shift;             //  SD_HWM_PVV


//==================================================================================
////////////////////   SD CARD   ////////////////////
//  SD_msx
/*
assign SD_DAT3 = ~sdcs;     // CS
assign SD_CMD = sdcmd;      // MOSI
assign SD_CLK = sdclk;

always @( posedge clk50mhz or posedge reset )begin
	if( reset )begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'h1;
	end else begin
		if( cpu_ADDR[15:0] == 16'hF700 && cpu_nWR == 0 )begin
		   sdcs <= o_cpu_data[0];
		end
		if( cpu_ADDR[15:0] == 16'hF701 && cpu_nWR == 0 )begin
			if( sdclk )begin
			     sddata <= {sddata[5:0], SD_DAT};
			end
			sdcmd <= o_cpu_data[7];
			sdclk <= 1'b0;
		end
		if( cpu_RD )begin
		  sdclk <= 1'b1;
		end
	end
end*/
//==================================================================================
//  STD_WW55_SD_n8vem
/*
// SD_PWR  EQU 080h   ; POWER OFF/ON=0/1 (positive logic)
// SD_CS   EQU 040h   ; NPN inverter, positive logic.
// SD_CLK  EQU 020h
// SD_DOUT EQU 01h
// SD_DIN  EQU 80h 
assign app_VV55Ain[7] = SD_DAT;
assign SD_DAT3 = app_portc[6];     // CS
assign SD_CMD = app_portc[0];      // MOSI
assign SD_CLK = app_portc[5];*/
//==================================================================================
//  SD_HWM_PVV
// SD_DATA_PORT 0xF000
// SD_CONF_PORT 0xF001
// 0x02 - power ON/OFF
// 0x01 - CS
// 0x40 - BUSY for MX2
assign SD_DAT3 = ~sdcs;     // CS
assign SD_CMD = sdcmd;      // MOSI
assign SD_CLK = sdclk ? c_sclk : 0;     // MODE0

// HardWareMan, [20.09.2024 23:08]
// Если c_sclk не гейтится (т.е. ебашит постоянно), то reset можно тестить и без завода в список чувствительности. Тогда тактовое дерево будет проще и быстрее.
// Максимум его надо будет синхронизировать (+1 регистр), но для таких простых проектов это даже не обязательно.
always @( negedge c_sclk )begin   // MODE0
	if( reset )begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'b1;
		spi_cnt <= 4'hF;
    end else begin
		if( cpu_ADDR[15:0] == 16'hF001 && cpu_nWR == 0 )begin     // SD_CONF_PORT
		   sdcs <= o_cpu_data[0];
		end
		
		if( cpu_ADDR[15:0] == 16'hF000 && cpu_nWR == 0 )begin     // SD_DATA_PORT
		  spi_cnt <= 4'h0;
		  spi_shift <= o_cpu_data;
		end
		
		if( spi_cnt < 4'h8 )begin
		  spi_cnt <= spi_cnt + 1'b1;
		  sdcmd <= spi_shift[7];
		  spi_shift <= { spi_shift[6:0], SD_DAT };
		  sdclk <= 1'b1;
		end else begin
		  if( spi_cnt == 4'h8 )begin                          // last bit latch
		      spi_cnt <= spi_cnt + 1'b1;
		      spi_shift <= { spi_shift[6:0], SD_DAT };
		  end
		  sdclk <= 1'b0;
		end

	end
end
//==================================================================================
endmodule