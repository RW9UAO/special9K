/*
    greetings to
    AlexBel, HardWareMan, Stanislav Yudin, svofski, Dolphin Soft, fifan
    and all of tg fahivets85

    build with Gowin_V1.9.8.11
*/

`define GW_IDE

module top_level(
    input   clkinput,
    input   btn_s1,       // pull down

    output  [2:0]tmds_d_p,
    output  [2:0]tmds_d_n,
    output  tmds_clk_p,
    output  tmds_clk_n,

	inout   ps2_kb_dat,
	inout   ps2_kb_clk,	

    output  [5:0]LED,
    output  wire [7:0]dbg,

    // tang 9k
    output  [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output  [1:0] O_psram_ck_n,
    inout   [1:0] IO_psram_rwds,
    inout   [15:0] IO_psram_dq,
    output  [1:0] O_psram_reset_n,
    output  [1:0] O_psram_cs_n,

		// SDCARD
		output wire		SD_CS,		// CS
		output wire 	SD_SCK,		// SCLK
		output wire 	SD_CMD,		// MOSI
		input  wire  	SD_DAT0	// MISO



);

wire    reset;
wire    reset_hdmi, lock27m, lockhdmi, lock200m;
wire    clkBinput;
wire    clk32mhz, clkB32mhz, clk200mhz, clk12mhz, clk2mhz;
reg clkB12mhz;
wire    clk_sound, clkB_sound;
wire    cpu_clk;
reg     [4:0]cpu_div;

wire [15:0]cpu_ADDR;
wire [7:0]o_cpu_data;
wire [7:0]i_cpu_data;
reg cpu_RESET;
wire delayed_reset_n;
wire cpu_RD;
wire cpu_nWR;
wire cpu_INTR;
wire cpu_INTE;
wire cpu_nMREQ;  // T80
wire cpu_nRD;    // T80
wire [7:0]cpu_DATA;
reg [10:0]resetcnt;

wire    [7:0]romdata;
wire    [15:0]mem_addr;
wire    [7:0]o_mem_data;
//reg    [7:0]o_mem_data;
wire    [13:0]Vmem_addr;
//wire    [15:0]Vmem_addr;
wire    [10:0]Vmem_data;
wire    memWR, VmemWR;

reg startupBB55 = 1;
wire CE_ROM_C000, CE_ROM_C800, CE_ROM_D000, CE_ROM_D800, CE_ROM_E000, CE_ROM_E800, CE_REG_F000, CE_REG_F800;
wire sys_K580BB55_RD;
wire sys_K580BB55_WR;
reg [7:0] sys_porta;
reg [7:0] sys_portb;
reg [7:0] sys_portc;
reg [7:0] sys_portr;
reg [2:0] sys_clrdata;
wire [7:0]sys_VV55Ain;
wire [5:0]sys_VV55Bin;
wire [3:0]sys_VV55Cin;
wire     kbshift, kbreset;
wire [5:0] KeyMap [11:0];
wire [5:0]func_keys;
reg     beep;
wire    [15:0]soundL;
wire    [15:0]soundR;
wire    [7:0]sd_o;

wire    vi53_wren, vi53_rden;
wire	[2:0]vi53_out;
wire	[7:0]vi53_odata;
wire    vi53_sel;

    assign  reset_hdmi = ( lock27m && lockhdmi ) ? 1'b0 : 1'b1;


// tang 9k
    assign  reset = ~btn_s1;                 // no debounce
    assign lock27m = 1;
    wire psram_clk, psram_clk_p;
    t9k_hdmi clkhdmi_inst( .clkout( clk_hdmi ), .lock( lockhdmi ), .clkin( clkinput ), .clkoutd3( psram_clk )   );
    t9k_200m clk200m(      .clkout( clk200mhz ),.lock( lock200m ), .clkin( clkinput ), .clkoutd(/*psram_clk*/));// 200 mhz for 800x600 @60hz video
    //t9k_psram t9k_psram(        .clkout(psram_clk),        .clkoutp(psram_clk_p),        .clkin(clkinput)    );


//    assign  clk_pixel_x5 = clk200mhz;
    assign  clk_pixel_x5 = clk_hdmi;
    //BUFG clk_st(    .O( clk_pixel_x5 ),    .I( clk_hdmi )    );
    //assign  psram_clk = clk200mhz;
    //assign  psram_clk = clk_hdmi;
    //BUFG clk_st(    .O( psram_clk ),    .I( clk_hdmi )    );

// pixel clock divider
    CLKDIV #(.DIV_MODE(5)) div5 (        .CLKOUT( clk_pixel ),        .HCLKIN( clk_pixel_x5 ),        .RESETN( 1'b1 ),        .CALIB( 1'b0 )    );

// Output Clock frequency = 32mhz for CPU
    CLOCK_DIV #(.CLK_SRC( 200.0 ), .CLK_DIV( 32.0 ), .PRECISION_BITS(16) ) cpuclkd ( .clk_src( clk200mhz ), .clk_div( clkB32mhz )    );

// Output Clock frequency = 48kHz
    CLOCK_DIV #(.CLK_SRC(  27.0 ), .CLK_DIV( 0.048 ),.PRECISION_BITS(16) ) sndclkd (.clk_src( clkinput   ), .clk_div( clkB_sound )    );
// Output Clock frequency = 12mhz for USB
//    CLOCK_DIV #(.CLK_SRC( 200.0 ), .CLK_DIV( 12.0 ), .PRECISION_BITS(16) ) usbclkd ( .clk_src( clk200mhz ), .clk_div( clkB12mhz )    );

    //BUFG clk_pix_inst(    .O( clk_pixel ),    .I( clk_pixeld5 )    );
    //BUFG clk_cpu_inst(    .O( clkB32mhz ),    .I( clk32mhz )    );
    //BUFG clk_audio_inst(    .O( clkB_sound ),    .I( clk_sound )    );
    //BUFG clk_usb_inst(    .O( clkB12mhz ),    .I( clk12mhz )    );

always @(posedge cpu_clk )begin
    if( reset || !delayed_reset_n || kbreset )begin
        resetcnt <= 0;
        cpu_RESET <= 1;
    end else begin
        if( resetcnt[10] )
            cpu_RESET <= 0;
        else
            resetcnt <= resetcnt + 1'b1;
    end
end
    

always @(posedge clkB32mhz )begin
    if( reset )begin
        cpu_div <= 5'b00000;
    end else begin
//        if( !psram_busy )
            cpu_div <= cpu_div + 1'b1;
    end
end
    //assign  cpu_clk = clkB32mhz;    // 32 mhz
    //assign  cpu_clk = cpu_div[0];   // 16 mhz
    //assign  cpu_clk = cpu_div[1];   // 8 mhz
    //assign  cpu_clk = cpu_div[2];   // 4 mhz
    assign  cpu_clk = cpu_div[3];   // 2 mhz
//assign  cpu_clk = cpu_div[4];   // 1 mhz
    assign  clk2mhz = cpu_div[3];   // 2 mhz

    assign  cpu_INTR = 1'b0;
    assign  i_cpu_data =( sys_K580BB55_RD && cpu_ADDR[1:0] == 2'b00 ) ? sys_VV55Ain :                                   // portA
                        ( sys_K580BB55_RD && cpu_ADDR[1:0] == 2'b01 ) ? { sys_VV55Bin, kbshift, /*tapein*/ 1'b0 } :     // portB, rows
                        ( sys_K580BB55_RD && cpu_ADDR[1:0] == 2'b10 ) ? { 4'b0000, sys_VV55Cin } :                      // portC
                        ( sys_K580BB55_RD && cpu_ADDR[1:0] == 2'b11 ) ? sys_portr :

//                        ( app_K580BB55_RD && cpu_ADDR[1:0] == 2'b00 ) ? app_VV55Ain :
//                        ( app_K580BB55_RD && cpu_ADDR[1:0] == 2'b01 ) ? app_VV55Bin :
//                        ( app_K580BB55_RD && cpu_ADDR[1:0] == 2'b10 ) ? { 4'b0000, app_VV55Cin } :
//                        ( app_K580BB55_RD && cpu_ADDR[1:0] == 2'b11 ) ? app_portr :
                        
//                        ( (cpu_ADDR[15:0] == 16'hF700 || cpu_ADDR[15:0] == 16'hF701) && cpu_RD ) ? sd_o :       // sd_msx
                        ( cpu_ADDR[15:0] == 16'hF000 && cpu_RD ) ? sd_o :                                       // SD_HWM_PVV
                        ( vi53_rden ) ? vi53_odata :                                                            // timer
                        (( CE_ROM_C000||CE_ROM_C800||CE_ROM_D000||startupBB55) ) ? romdata :
//                        ( (cpu_ADDR[15:14] == 2'b11 || startupBB55) && cpu_RD ) ? romdata :
                        ( cpu_RD ) ? o_mem_data :                                                         // RAM
                        8'hFF;

    assign  CE_ROM_C000 = ( cpu_ADDR[15:11] == 5'b11000 ) ? 1'b1 : 1'b0;    // ROM, ro
    assign  CE_ROM_C800 = ( cpu_ADDR[15:11] == 5'b11001 ) ? 1'b1 : 1'b0;    // ROM, ro
    assign  CE_ROM_D000 = ( cpu_ADDR[15:11] == 5'b11010 ) ? 1'b1 : 1'b0;    // SDOS, ro
    assign  CE_ROM_D800 = ( cpu_ADDR[15:11] == 5'b11011 ) ? 1'b1 : 1'b0;    // SDOS buffers, rw
    assign  vi53_sel = cpu_ADDR[15:2] == 14'h3800;      // 0xE00x
    assign  CE_ROM_E800 = ( cpu_ADDR[15:11] == 5'b11101 ) ? 1'b1 : 1'b0;    // SP580 - BB55
    assign  CE_REG_F000 = ( cpu_ADDR[15:11] == 5'b11110 ) ? 1'b1 : 1'b0;    // SP580 - BB55 kbd, STD - BB55
    assign  CE_REG_F800 = ( cpu_ADDR[15:11] == 5'b11111 ) ? 1'b1 : 1'b0;    // SP580 - ROM, STD - BB55 kbd

    assign  sys_K580BB55_RD = ( CE_REG_F800 && cpu_RD  == 1'b1 ) ? 1'b1 : 1'b0;
    assign  sys_K580BB55_WR = ( CE_REG_F800 && cpu_nWR == 1'b0 ) ? 1'b1 : 1'b0;
    //assign  app_K580BB55_RD = ( CE_REG_F000 && cpu_RD  == 1'b1 ) ? 1'b1 : 1'b0;
    //assign  app_K580BB55_WR = ( CE_REG_F000 && cpu_nWR == 1'b0 ) ? 1'b1 : 1'b0;

    assign  vi53_wren = ( vi53_sel && cpu_nWR == 1'b0 ) ? 1'b1 : 1'b0;
    assign  vi53_rden = ( vi53_sel && cpu_RD  == 1'b1 ) ? 1'b1 : 1'b0;

    assign  mem_addr = startupBB55 ? {2'b11, cpu_ADDR[13:0]} :          // startup
                       cpu_ADDR;                                        // normal
    assign  memWR =  ( cpu_nWR == 0 && ( cpu_ADDR[15:14] != 2'b11 || CE_ROM_D800) ); // don`t write to ROM area
    assign  VmemWR = ( cpu_nWR == 0 &&   cpu_ADDR[15:14] == 2'b10 ); 

//==================================================================================
    t9k_rom ROM_inst(
        .dout( romdata ),
        .clk( clkB32mhz ),
        .oce( 1'b1 ),
        .ce( 1'b1 ),
        .reset( reset ),
        .ad( cpu_ADDR[12:0] )
    );

    t9k_vmem VRAM_inst(
        .reseta( reset ),
        .resetb( reset_hdmi ),
        .oce( 1'b1 ),
        .clka( clkB32mhz ),
        .cea( VmemWR ),
        .ada( cpu_ADDR[13:0] ),
        .din( { sys_portc[7], sys_portc[6], sys_portc[4], o_cpu_data } ),

        .clkb( clk_pixel ),
        .ceb( 1'b1 ),
        .adb( Vmem_addr ),
        .dout( Vmem_data )
    );


assign delayed_reset_n = psram_calib;
    psram_cnt psram_cnt_instance(
        .dbg( dbg ),
        .clk27M( clkinput ),
        .psram_clk( psram_clk ),
        .clk_bus( clkB32mhz ),
        .lock_mem( lockhdmi ),
        .reset( reset ),
        .psram_calib( psram_calib ),

        .A( {5'b00000, cpu_ADDR} ),
        .DI( o_cpu_data ),
        .DO( o_mem_data ),
//        .WR( memWR ),                                           //
        .WR( ~cpu_nWR ),
        .RD( cpu_RD ),
        .O_psram_ck(O_psram_ck),
        .O_psram_ck_n(O_psram_ck_n),
        .IO_psram_rwds(IO_psram_rwds),
        .IO_psram_dq(IO_psram_dq),
        .O_psram_reset_n(O_psram_reset_n),
        .O_psram_cs_n(O_psram_cs_n)
    );

//assign  LED = ~o_mem_data[5:0];
assign  LED[0] = ~cpu_RD;
assign  LED[1] = ~memWR;
assign  LED[2] = ~psram_calib;
assign  LED[3] = ~cpu_RESET;
assign  LED[4] = kbshift;
//assign  LED[5] = 1;
/*
wire [15:0] dout;
wire psram_busy;
reg psram_rd;
reg psram_wr;
reg psram_work;
//assign o_mem_data = cpu_ADDR[0] ? dout[15:8] : dout[7:0];
assign O_psram_reset_n = ~reset;

reg psram_rd_cpu_d, psram_wr_cpu_d;
always @( posedge psram_clk )begin
    psram_wr_cpu_d <= memWR;   // sample wr edge
    psram_rd_cpu_d <= cpu_RD;   // sample rd edge
end
wire psram_rd_cmd = cpu_RD & ~psram_rd_cpu_d; // pos edge
wire psram_wr_cmd = memWR & ~psram_wr_cpu_d;
wire rdcpu_finished;

PsramController #(    .FREQ(74_250_000),    .LATENCY(3) ) mem_ctrl(
    .clk( psram_clk ), .clk_p( psram_clk_p ), .resetn( ~reset ),
    .read( psram_rd ), .write( psram_wr ),      // Set to 1 to read from RAM
    .byte_write( 1'b1 ),
    .addr( {6'b000000, cpu_ADDR} ),
    .din( {o_cpu_data, o_cpu_data} ), .dout( dout ),
    .busy( psram_busy ),                                                                            // 1 while an operation is in progress

    .resetn_o( delayed_reset_n ),     // psram controller dictates system reset
    .rdcpu_finished( rdcpu_finished ),

    .O_psram_ck(O_psram_ck), .IO_psram_rwds(IO_psram_rwds), .IO_psram_dq(IO_psram_dq),
    .O_psram_cs_n(O_psram_cs_n)
);

always @(negedge rdcpu_finished) 
    o_mem_data <= cpu_ADDR[0] ? dout[15:8] : dout[7:0];


always @(posedge reset or posedge psram_clk )begin
    if( reset )begin
        psram_rd <= 0;
        psram_wr <= 0;
        psram_work <= 0;
    end else begin
        if( !cpu_RD && !memWR )begin
            psram_rd <= 0;
            psram_wr <= 0;
            psram_work <= 0;
        end else
        if( cpu_RD *&& cpu_ADDR[15:14] != 2'b11/ )begin
            if( !psram_work )begin
                psram_rd <= 1;
                psram_work <= 1;
            end else begin
                if( !psram_busy )
                    psram_rd <= 0;
                else begin
//                    if( cpu_ADDR[0] ) o_mem_data <= dout[15:8];
//                    else  o_mem_data <= dout[7:0];
                end
            end
        end else
        if( memWR )begin
            if( !psram_work )begin
                psram_wr <= 1;
                psram_work <= 1;
            end else begin
                if( !psram_busy )
                    psram_wr <= 0;
            end
        end
    end
end


assign dbg[0] = cpu_RD | memWR;
assign dbg[1] = psram_rd_cmd;
assign dbg[2] = psram_wr_cmd;
assign dbg[3] = psram_busy;
assign dbg[4] = rdcpu_finished;
assign dbg[7] = psram_clk;
*/

//==================================================================================
// K580BB55
always @(posedge cpu_RESET or posedge cpu_clk )begin
    if( cpu_RESET == 1'b1 )begin
        sys_porta <= 8'h00;
        sys_portb <= 8'h00;
        sys_portc <= 8'h00;
        sys_portr <= 8'h00;
        sys_clrdata <= 3'b111;
/*
        app_porta <= 8'h00;
        app_portb <= 8'h00;
        app_portc <= 8'h00;
        app_portr <= 8'h00;
        app_clrdata <= 3'b111;*/

        startupBB55 <= 1;
    end else begin
    
        if( sys_K580BB55_WR == 1'b1 )begin
            case( cpu_ADDR[1:0] )
            2'b00:sys_porta <= o_cpu_data;
            2'b01:sys_portb <= o_cpu_data;
            2'b10: begin
                sys_portc <= o_cpu_data;
                sys_clrdata <= { ~o_cpu_data[4], ~o_cpu_data[6], ~o_cpu_data[7] };
                beep <= ~o_cpu_data[5];
                end
            2'b11: begin
                sys_portr <= o_cpu_data;
                startupBB55 <= 1'b0;
                if( o_cpu_data[7] == 1'b0 && o_cpu_data[3:1] == 3'b101 )
                    beep <= ~o_cpu_data[0];
                end
            endcase
        end
/*
        if( app_K580BB55_WR == 1'b1 )begin
            case( cpu_ADDR[1:0] )
            2'b00:app_porta <= o_cpu_data;
            2'b01:app_portb <= o_cpu_data;
            2'b10: begin
                app_portc <= o_cpu_data;
                app_clrdata <= { ~o_cpu_data[4], ~o_cpu_data[6], ~o_cpu_data[7] };
                end
            2'b11: begin
                app_portr <= o_cpu_data;
                end
            endcase
        end*/

    end
end

//==================================================================================
/*
k580wm80a cpuA(
	.clk( cpu_clk ),
	.ce( 1'b1 ),
	.reset( cpu_RESET ),
	.intr( cpu_INTR ),
	.idata( i_cpu_data ),
	.addr( cpu_ADDR ),
	.sync(),
	.rd( cpu_RD ),
	.wr_n( cpu_nWR ),
	.inta_n(),
	.odata( o_cpu_data ),
	.inte_o( cpu_INTE )
);*/
//==================================================================================

vm80a cpuC(
	.pin_clk( clkB32mhz ),			// global module clock (no in original 8080)
	.pin_f1( cpu_clk ),			// clock phase 1 (used as clock enable)
	.pin_f2( ~cpu_clk ),			// clock phase 2 (used as clock enable)
	.pin_reset( cpu_RESET ),		// module reset
	.pin_a( cpu_ADDR ),			// address bus outputs
    .pin_d( cpu_DATA ),			//inout
	.pin_hold( 1'b0 ),		//
	.pin_hlda(),		//
	.pin_ready( 1'b1 ),		//
	.pin_wait(),		//
	.pin_int( cpu_INTR ),			//
	.pin_inte( cpu_INTE ),		//
	.pin_sync(),		//
	.pin_dbin( cpu_RD ),
	.pin_wr_n( cpu_nWR )
);
assign  cpu_DATA = cpu_RD ? i_cpu_data : 8'hZZ;
assign  o_cpu_data = cpu_DATA;
/*
//==================================================================================
//T80Na #(.Mode(2) ) cpuB(      // i8080
T80Na #(.Mode(0) ) cpuB(        // Z80
      .RESET_n( ~reset ),
      .CLK_n( cpu_clk ),
      .WAIT_n( 1'b1 ),
      .INT_n( 1'b1 ),
      .NMI_n( 1'b1 ),
      .BUSRQ_n( 1'b1 ),
      .M1_n(),
      .MREQ_n( cpu_nMREQ ),
      .IORQ_n(),
      .RD_n( cpu_nRD ),
      .WR_n( cpu_nWR ),
      .RFSH_n(),
      .HALT_n(),
      .BUSAK_n(),
      .A( cpu_ADDR ),
      .D_i( i_cpu_data ),
      .D_o( o_cpu_data ),
      // extended functions
      .Z80N_dout_o(),
      .Z80N_data_o(),
      // rw9uao
      .IntEnab( cpu_INTE )

);*/

//parameter DLEN = 25;
//reg [DLEN:0]delay;
//always @(posedge clkB_sound or posedge cpu_RESET )begin
//    if( cpu_RESET == 1'b1 )
//        delay <= 0;
//    else
//        delay <= {delay[DLEN-1:0], vi53_out[0]};
//end

    assign  soundL = { vi53_out[0], beep, 14'b0 };
    assign  soundR = { vi53_out[0], beep, 14'b0 };
//    assign  soundL = { delay[DLEN] | vi53_out[0], beep, 14'b0 };
//    assign  soundR = { delay[DLEN] | vi53_out[0], beep, 14'b0 };
//==================================================================================
// KeyMap[10][4] - '1'
assign  sys_VV55Ain ={(sys_portb[2] ? 1'b1 : KeyMap[7][0]) & (sys_portb[3] ? 1'b1 : KeyMap[7][1]) & (sys_portb[4] ? 1'b1 : KeyMap[7][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[7][3]) & (sys_portb[6] ? 1'b1 : KeyMap[7][4]) & (sys_portb[7] ? 1'b1 : KeyMap[7][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[6][0]) & (sys_portb[3] ? 1'b1 : KeyMap[6][1]) & (sys_portb[4] ? 1'b1 : KeyMap[6][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[6][3]) & (sys_portb[6] ? 1'b1 : KeyMap[6][4]) & (sys_portb[7] ? 1'b1 : KeyMap[6][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[5][0]) & (sys_portb[3] ? 1'b1 : KeyMap[5][1]) & (sys_portb[4] ? 1'b1 : KeyMap[5][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[5][3]) & (sys_portb[6] ? 1'b1 : KeyMap[5][4]) & (sys_portb[7] ? 1'b1 : KeyMap[5][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[4][0]) & (sys_portb[3] ? 1'b1 : KeyMap[4][1]) & (sys_portb[4] ? 1'b1 : KeyMap[4][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[4][3]) & (sys_portb[6] ? 1'b1 : KeyMap[4][4]) & (sys_portb[7] ? 1'b1 : KeyMap[4][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[3][0]) & (sys_portb[3] ? 1'b1 : KeyMap[3][1]) & (sys_portb[4] ? 1'b1 : KeyMap[3][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[3][3]) & (sys_portb[6] ? 1'b1 : KeyMap[3][4]) & (sys_portb[7] ? 1'b1 : KeyMap[3][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[2][0]) & (sys_portb[3] ? 1'b1 : KeyMap[2][1]) & (sys_portb[4] ? 1'b1 : KeyMap[2][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[2][3]) & (sys_portb[6] ? 1'b1 : KeyMap[2][4]) & (sys_portb[7] ? 1'b1 : KeyMap[2][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[1][0]) & (sys_portb[3] ? 1'b1 : KeyMap[1][1]) & (sys_portb[4] ? 1'b1 : KeyMap[1][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[1][3]) & (sys_portb[6] ? 1'b1 : KeyMap[1][4]) & (sys_portb[7] ? 1'b1 : KeyMap[1][5]),
                      (sys_portb[2] ? 1'b1 : KeyMap[0][0]) & (sys_portb[3] ? 1'b1 : KeyMap[0][1]) & (sys_portb[4] ? 1'b1 : KeyMap[0][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[0][3]) & (sys_portb[6] ? 1'b1 : KeyMap[0][4]) & (sys_portb[7] ? 1'b1 : KeyMap[0][5]) };

assign sys_VV55Bin =   (sys_porta[0] ? 6'b111111 : KeyMap[0])  &  (sys_porta[1] ? 6'b111111 : KeyMap[1]) &
                       (sys_porta[2] ? 6'b111111 : KeyMap[2])  &  (sys_porta[3] ? 6'b111111 : KeyMap[3]) &
                       (sys_porta[4] ? 6'b111111 : KeyMap[4])  &  (sys_porta[5] ? 6'b111111 : KeyMap[5]) &
                       (sys_porta[6] ? 6'b111111 : KeyMap[6])  &  (sys_porta[7] ? 6'b111111 : KeyMap[7]) &
                       (sys_portc[0] ? 6'b111111 : KeyMap[8])  &  (sys_portc[1] ? 6'b111111 : KeyMap[9]) &
                       (sys_portc[2] ? 6'b111111 : KeyMap[10]) &  (sys_portc[3] ? 6'b111111 : KeyMap[11]);

assign sys_VV55Cin ={ (sys_portb[2] ? 1'b1 : KeyMap[11][0]) & (sys_portb[3] ? 1'b1 : KeyMap[11][1]) & (sys_portb[4] ? 1'b1 : KeyMap[11][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[11][3]) & (sys_portb[6] ? 1'b1 : KeyMap[11][4]) & (sys_portb[7] ? 1'b1 : KeyMap[11][5]),    // C3
                      (sys_portb[2] ? 1'b1 : KeyMap[10][0]) & (sys_portb[3] ? 1'b1 : KeyMap[10][1]) & (sys_portb[4] ? 1'b1 : KeyMap[10][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[10][3]) & (sys_portb[6] ? 1'b1 : KeyMap[10][4]) & (sys_portb[7] ? 1'b1 : KeyMap[10][5]),    // C2
                      (sys_portb[2] ? 1'b1 : KeyMap[9][0])  & (sys_portb[3] ? 1'b1 : KeyMap[9][1])  & (sys_portb[4] ? 1'b1 : KeyMap[9][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[9][3])  & (sys_portb[6] ? 1'b1 : KeyMap[9][4])  & (sys_portb[7] ? 1'b1 : KeyMap[9][5]),     // C1
                      (sys_portb[2] ? 1'b1 : KeyMap[8][0])  & (sys_portb[3] ? 1'b1 : KeyMap[8][1])  & (sys_portb[4] ? 1'b1 : KeyMap[8][2]) &
                      (sys_portb[5] ? 1'b1 : KeyMap[8][3])  & (sys_portb[6] ? 1'b1 : KeyMap[8][4])  & (sys_portb[7] ? 1'b1 : KeyMap[8][5]) };   // C0
//==================================================================================
ps2kbd kbdPS_inst(
    .ps2_kb_dat( ps2_kb_dat ),
    .ps2_kb_clk( ps2_kb_clk ),
    .clk( clkinput ),
    .reset( reset ),
.dbg(aaaa),
    .KeyMap0( KeyMap[0] ),    .KeyMap1( KeyMap[1] ),    .KeyMap2( KeyMap[2] ),    .KeyMap3( KeyMap[3] ),
    .KeyMap4( KeyMap[4] ),    .KeyMap5( KeyMap[5] ),    .KeyMap6( KeyMap[6] ),    .KeyMap7( KeyMap[7] ),
    .KeyMap8( KeyMap[8] ),    .KeyMap9( KeyMap[9] ),    .KeyMap10( KeyMap[10] ),    .KeyMap11( KeyMap[11] ),
    .Func( func_keys )
);
    assign  kbshift = ~func_keys[0];

assign  kbreset = func_keys[1];
assign  LED[5] = ~aaaa;
// ==================================================================================================
k580vi53 timer_ins(
    .reset( cpu_RESET ),
    .clk_sys( clkB32mhz ),
    .addr( cpu_ADDR[1:0] ),
    .din( o_cpu_data ),
    .dout( vi53_odata ),
    .wr( vi53_wren ),
    .rd( vi53_rden ),
    .clk_timer( { vi53_out[1], clk2mhz, clk2mhz } ),
    .gate( { 1'b1, 1'b1, ~vi53_out[2] } ),
    .out( vi53_out ),
    .sound_active()            
);
// ==================================================================================================
sdos sdos_inst(
    .reset( reset ),
    .c_sclk( cpu_clk ), // 2 mhz
    .cpu_ADDR( cpu_ADDR ),
    .o_cpu_data( o_cpu_data ),
    .cpu_nWR( cpu_nWR ),
    .sd_o( sd_o ),

    .SD_DAT( SD_DAT0 ),					//	SD Card Data
    .SD_DAT3( SD_CS ),				//	SD Card Data 3
    .SD_CMD( SD_CMD ),					//	SD Card Command Signal
    .SD_CLK( SD_SCK )					//	SD Card Clock
);
    // ==================================================================================================
    // video
    // Horizontal Timings
    wire [11:0] ActivePixels;
    wire [11:0]TotalPixels;
    //    Vertical Timings
    wire [11:0]ActiveLines;
    wire [11:0]TotalLines;

    parameter LinesMax = 256;
    parameter PixelMax = 384;

    wire [11:0]h_counter;
    wire [11:0]v_counter;
    reg r, g, b, p;
    
    reg [2:0]hscale = 0;
    reg [2:0]vscale = 0;
    reg [7:0]vcnt = 0;
    reg [8:0]hcnt = 0;

    reg [7:0]vid_0_reg;
    reg [7:0]vid_1_reg;    
    reg [7:0]vid_b_reg;
    reg [7:0]vid_c_reg;

    parameter Hscalefactor = 2;
    //parameter HOffset_c = 4;// 800x600
    parameter HOffset_c = 256 - 8;
    reg [8:0]hoffset = 0;
    reg leftborder = 0;

    parameter Vscalefactor = 2;
    //parameter VOffset_c = 32;// 800x600;
    parameter VOffset_c = 104;
    reg [7:0]voffset = 0;
    reg topborder = 0;
    reg botborder = 0;
    
    reg screen;
    reg screen1;
    reg blank;
    wire [7:0]Rout;
    wire [7:0]Gout;
    wire [7:0]Bout;
    
    assign Rout = {r, r, r, r, r, r, r, r};
    assign Gout = {g, g, g, g, g, g, g, g};
    assign Bout = {b, p, b, b, b, b, b, b};

    assign  Vmem_addr = {{6'h10 + hcnt[8:3]}, vcnt[7:0] };
    //assign  Vmem_addr = {{8'h90 + hcnt[8:3]}, vcnt[7:0] };
    //assign  Vmem_addr = {{8'hC0 + hcnt[8:3]}, vcnt[7:0] };


//reg t1;
//reg t2;
//assign dbg = 8'h00;
//assign dbg[0] = clkB32mhz;
//assign dbg[1] = t2;
//assign dbg[2] = topborder;
//assign dbg[3] = leftborder;

//  counters
always @( posedge reset_hdmi or posedge clk_pixel )begin
    if( reset_hdmi == 1'b1 )begin
        //h_counter <= 0;
    end else begin
        if ( h_counter == (TotalPixels-1) ) begin
           // new line begin, reset all counters
            hscale <= 0;
            hoffset <= 0;     // left offset
            hcnt <= 0;        // speccy pixel counter
            leftborder <= 1'b1;
            if( v_counter == (TotalLines-1) )begin
              // new screen begin, reset all counters
              vscale <= 0;
              voffset <= 0;
              vcnt <= 0;
              topborder <= 1'b1;
              botborder <= 1'b0;
            end else begin                
                if( vscale == (Vscalefactor-1) )begin
                  vscale <= 0;
                   if( topborder == 1'b0 )begin
                       if( vcnt < (LinesMax-1) )begin
                           vcnt <= vcnt + 1'b1;
                       end else begin
                           botborder <= 1'b1;
                       end
                   end
                end else begin
                   vscale <= vscale + 1'b1;
                end
                
               if( voffset < VOffset_c )begin
                   voffset <= voffset + 1'b1;
               end else begin
                   topborder <= 1'b0;
               end    
            end

        end else begin
           if( hscale == (Hscalefactor-1) )begin
               hscale <= 0;
               if( leftborder == 1'b0 )begin
                   if( hcnt < (PixelMax + 7) )begin
                       hcnt <= hcnt + 1'b1;
                   end
               end
           end else begin
               hscale <= hscale + 1'b1;
           end
           
           if( hoffset < HOffset_c) begin
               hoffset <= hoffset + 1'b1;
           end else begin
               leftborder <= 1'b0;
           end
        end
    end
end

//always @(negedge clk_pixel )begin
always @(posedge clk_pixel )begin

  if( hscale == (Hscalefactor-1) )begin                  // wait for previos vid_dot finish
    case( hcnt[2:0] )
        3'b100: begin 
            vid_0_reg <= Vmem_data[7:0];    // b/w pixel data
		    vid_1_reg <= ~Vmem_data[10:8];    // color pixel data
            end
		3'b111: begin
			vid_b_reg <= vid_0_reg;
			vid_c_reg <= vid_1_reg;
			screen1 <= screen;
		end 
    endcase
  end
end

// enable video output
always @( posedge clk_pixel )begin
	if ( h_counter >= HOffset_c && h_counter < (HOffset_c + (PixelMax * Hscalefactor)) && v_counter > VOffset_c && v_counter <= (VOffset_c + (LinesMax * Vscalefactor)) ) begin
		screen <= 1'b1;
	end else begin
		screen <= 1'b0;
	end
end


// DE
always @(posedge clk_pixel )begin
    if( v_counter < ActiveLines )begin
//        KGI <= 1'b0;
        if( h_counter < ActivePixels )begin
            blank <= 1'b0;
        end else begin
            blank <= 1'b1;
        end
    end else begin
        blank <= 1'b1;
        if( v_counter < (ActiveLines + 100) )begin
//            KGI <= 1'b1;
        end else begin
//            KGI <= 1'b0;
        end
    end
end
wire vid_dot;
//==================================================
// use multipexor as pixel shift
assign vid_dot = 	( hcnt[2:0] == 3'b000) ? vid_b_reg[7] :
					( hcnt[2:0] == 3'b001) ? vid_b_reg[6] :
					( hcnt[2:0] == 3'b010) ? vid_b_reg[5] :
					( hcnt[2:0] == 3'b011) ? vid_b_reg[4] :
					( hcnt[2:0] == 3'b100) ? vid_b_reg[3] :
					( hcnt[2:0] == 3'b101) ? vid_b_reg[2] :
					( hcnt[2:0] == 3'b110) ? vid_b_reg[1] :
						vid_b_reg[0];


//always @(negedge clk_pixel )begin
always @(posedge clk_pixel )begin
    if( blank == 1'b0 )begin
        if (screen1 == 1) begin
						r <= vid_dot ? vid_c_reg[2] : 1'b0;
						g <= vid_dot ? vid_c_reg[1] : 1'b0;
						b <= vid_dot ? vid_c_reg[0] : 1'b0;
						p <= vid_dot ? vid_c_reg[0] : 1'b0;
        end else begin  // border is black
						r <= 0;
						g <= 0;
						b <= 0; 
						p <= 1;
        end
    end else begin  // blank
						b <= 0;
						r <= 0;
						g <= 0;
						p <= 0;
    end
end

    // ==================================================================================================
    // HDMI output
    logic[2:0] tmds;
/*
    reg [7:0]R;    reg [7:0]G;    reg [7:0]B;
always @(negedge clk_pixel )begin
    // color bars
        if( h_counter >= (0 * 100) && h_counter < (1 * 100) )begin  R <= 8'hFF;  G <= 8'hFF;  B <= 8'h00;    // yellow            
        end else
        if( h_counter >=  (1 * 100) && h_counter < (2 * 100) )begin R <= 8'h00; G <= 8'hFF;   B <= 8'hFF;     // cyan
        end else
        if( h_counter >= (2 * 100) && h_counter < (3 * 100) )begin  R <= 8'h00; G <= 8'hFF;            B <= 8'h00;     // green
        end else
        if( h_counter >= (3 * 100) && h_counter < (4 * 100) )begin  R <= 8'hFF; G <= 8'h00;            B <= 8'hFF;     // magenta
        end else
        if( h_counter >= (4 * 100) && h_counter < (5 * 100) )begin R <= 8'hFF; G <= 8'h00;            B <= 8'h00;     // red
        end else
        if( h_counter >= (5 * 100) && h_counter < (6 * 100) )begin R <= 8'h00; G <= 8'h00;            B <= 8'hFF;     // blue
        end else
        if( h_counter >= (6 * 100) && h_counter < (7 * 100) )begin R <= 8'h00; G <= 8'h00;            B <= 8'h00;     // black
        end else begin    R <= 8'hFF;  G <= 8'hFF;           B <= 8'hFF;  end  // white
end*/


    hdmi #(     //.VIDEO_ID_CODE( 30 ),   // 1440x576@50Hz, 31.250 kHz     54MHz, 270MHz
                //.VIDEO_ID_CODE( 4 ),  // 1280x720@60Hz = 74.25mhZ, 371,25MHz
            .VIDEO_ID_CODE( 19 ),  // 1280x720@50Hz = 74.25mhZ, 371,25MHz
                //.VIDEO_ID_CODE( 1 ),  // 640x480 = 25.2mhZ, 126MHz
            //.VIDEO_ID_CODE( 77 ),  // 800x600 = 40mhZ, 200MHz
                //.VIDEO_ID_CODE( 16 ),   // 1920x1080@50Hz = 123.750MHz, 618.750MHz NOPLL!!!
                //.VIDEO_ID_CODE( 16 ),   // 1920x1080@60Hz = 148.5MHz, 742.5MHz  not support
                //.VIDEO_ID_CODE( 34 ),   // 1920x1080@30Hz = 74.25mhZ, 371,25MHz  not support
                //.VIDEO_ID_CODE( 20 ),   // 1920x1080@50Hz = 74.25mhZ, 371,25MHz  not support
                //.VIDEO_ID_CODE( 2 ),    // 720x480 = 27.027 MHz
                //.VIDEO_ID_CODE( 17 ),    // 720x576 = 27.0 MHz, 135mhz
            .DVI_OUTPUT(0), 
            //.VIDEO_REFRESH_RATE( 60.0 ),
            //.VIDEO_REFRESH_RATE( 59.94 ),
            .VIDEO_REFRESH_RATE( 50.0 ),
            //.VIDEO_REFRESH_RATE( 29.97 ),
            .IT_CONTENT(1),
            .AUDIO_RATE( 48000 ), 
            .AUDIO_BIT_WIDTH( 16 ),
            .START_X(0),
            .START_Y(0) )

    hdmi( .clk_pixel_x5( clk_pixel_x5 ), 
            .clk_pixel( clk_pixel ), 
            .clk_audio( clkB_sound ),
//            .rgb( {R, G, B} ), 
            .rgb( {Rout, Gout, Bout} ), 
            .reset( reset_hdmi ),
            .audio_sample_word( {soundL, soundR} ),
            .tmds( tmds ), 
            .tmds_clock( tmdsClk ), 
            .cx( h_counter ), 
            .cy( v_counter ),
            .frame_width( TotalPixels ),
            .frame_height( TotalLines ),
            .screen_width( ActivePixels ),
            .screen_height( ActiveLines )
    );

    // Gowin LVDS output buffer
    ELVDS_OBUF tmds_bufds [3:0] (
        .I({clk_pixel, tmds}),
        .O({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
    );

endmodule