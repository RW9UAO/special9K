module psram_cnt(
    output wire [7:0]dbg,
    input clk27M,
    input psram_clk,
    input clk_bus,
    input lock_mem,
    input reset,
    output psram_calib,

    input [20:0]A,
    input [7:0]DI,
    output reg[7:0]DO,
    input WR,
    input RD,

    output [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output [1:0] O_psram_ck_n,
    inout [1:0] IO_psram_rwds,
    inout [15:0] IO_psram_dq,
    output [1:0] O_psram_reset_n,
    output [1:0] O_psram_cs_n
);

parameter state_init = 0;
parameter state_idle = 1;
parameter state_read = 2;
parameter state_write = 3;

reg [63:0]wr_data;
wire [63:0]rd_data;
wire rd_data_valid;
reg [20:0]addr;
reg cmd;
reg cmd_en;
wire init_calib;
reg [7:0]data_mask;
wire clk_logic;

reg [1:0]state = state_init;
reg [5:0]cycle = 0;
reg [1:0]read_cycle = 0;
reg [1:0]rd_req = 0;
reg [1:0]wr_req = 0;
reg rd_ready;
reg [7:0]buff;

reg lock;

assign dbg[0]=RD;
assign dbg[1]=WR;
assign dbg[2]=init_calib;
assign dbg[3]=cmd_en;
assign dbg[4]=rd_data_valid;
assign dbg[5]=rd_ready;
assign dbg[6]=state[0];
assign dbg[7]=DO[0];
assign psram_calib = init_calib;

	PSRAM_Memory_Interface_HS_Top lowmem_instance(
		.clk( clk27M ),
		.memory_clk( psram_clk ),
        .pll_lock( lock_mem ),
		.rst_n( ~reset ),
		.O_psram_ck( O_psram_ck ),
		.O_psram_ck_n( O_psram_ck_n ),
		.IO_psram_dq( IO_psram_dq ),
		.IO_psram_rwds( IO_psram_rwds ),
		.O_psram_cs_n( O_psram_cs_n ),
		.O_psram_reset_n( O_psram_reset_n ),
		.wr_data( wr_data ),
		.rd_data( rd_data ),
		.rd_data_valid( rd_data_valid ),
		.addr( addr ),
		.cmd( cmd ),
		.cmd_en( cmd_en ),
		.init_calib( init_calib ),
		.clk_out( clk_logic ),
		.data_mask( data_mask )
	);


    always @(posedge reset or posedge clk_logic )begin
        if( reset == 1'b1 )begin
            cmd <= 1'b0;
            cmd_en <= 1'b0;
            data_mask <= 8'h00;//8'hFF;
            cycle <= 0;
            rd_ready <= 1'b0;
            lock <= 0;
        end else begin

            rd_req[0] <= RD;            
            wr_req[0] <= WR;
            rd_req[1] <= rd_req[0];
            wr_req[1] <= wr_req[0];

            if( !wr_req[1] && !rd_req[1] )
                lock <= 0;

            case( state )
                state_init: begin                             // 00
                    if( init_calib == 1'b1 )begin
                        state <= state_idle;
                    end
                end
                state_idle: begin                             // 01
                    cycle <= 0;
                    if( wr_req[1] == 1'b1 && !lock )begin
                        state <= state_write;
                        addr <= A;
                        wr_data <= {56'hFFFFFFF, DI};
                        data_mask <= 8'b11111110;
                        cmd <= 1'b1; // write
                        cmd_en <= 1'b1;
                        cycle <= cycle + 1'b1;
                    end else if( rd_req[1] == 1'b1  && !lock )begin
                        rd_ready <= 1'b0;
                        state <= state_read;
                        addr <= A;
                        cmd <= 1'b0; // read 
                        cmd_en <= 1'b1;
                        read_cycle <= 0;
                        cycle <= cycle + 1'b1;
                    end
                end
                state_read: begin                             // 10
                        cmd_en <= 1'b0;
                        cycle <= cycle + 1'b1;
                        if( rd_data_valid == 1'b1 && read_cycle < 3 )begin
                            if( read_cycle == 0 )begin
                                rd_ready <= 1'b1;
                                buff <= rd_data[7:0];
                            end
                            read_cycle <= read_cycle + 1'b1;
                        end
                        if( cycle == 13 )begin
//                        if( cycle == 20 )begin
                            state <= state_idle;
//                            lock <= 1;
                        end
                end
                state_write: begin                             // 11
                    cmd_en <= 1'b0;
                    cycle <= cycle + 1'b1;
                    data_mask <= 8'hFF;
                    if( cycle == 13 )begin
//                    if( cycle == 20 )begin
                        state <= state_idle;
//                        lock <= 1;
                    end
                end
            endcase
        end
    end

    always @(posedge clk_bus )begin
        if( rd_ready == 1'b1) begin
            DO <= buff;
        end
    end

//always @(negedge rd_data_valid )begin
//    DO <= rd_data[7:0];
//end

endmodule