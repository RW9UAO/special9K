module keyboard(
    input   CLK,
    input   CLK_USB,
    input   RESET,

    inout   USB_DP,
    inout   USB_DN,


    //output  wire [5:0]dbg,
    output  reg[5:0]KeyMap0,
    output  reg[5:0]KeyMap1,
    output  reg[5:0]KeyMap2,
    output  reg[5:0]KeyMap3,
    output  reg[5:0]KeyMap4,
    output  reg[5:0]KeyMap5,
    output  reg[5:0]KeyMap6,
    output  reg[5:0]KeyMap7,
    output  reg[5:0]KeyMap8,
    output  reg[5:0]KeyMap9,
    output  reg[5:0]KeyMap10,
    output  reg[5:0]KeyMap11,
    output  reg[5:0]Func            // x, x, x, x, reset, shift
);


parameter LEFT_CTRL	= 8'h01;
parameter LEFT_SHIFT	= 8'h02;
parameter LEFT_ALT	= 8'h04;
parameter LEFT_WIN	= 8'h08;
parameter RIGHT_CTRL	= 8'h10;
parameter RIGHT_SHIFT	= 8'h20;
parameter RIGHT_ALT	= 8'h40;
parameter RIGHT_WIN	= 8'h80;
parameter BOTH_CTRL = 8'h11;
parameter BOTH_SHIFT	= 8'h22;
parameter BOTH_ALT	= 8'h44;

wire [7:0]key0;
wire [7:0]key1;
wire [7:0]key2;
wire [7:0]key3;
wire [7:0]key4;
wire [7:0]key5;
wire [7:0]key6;
wire new_packet;
reg [1:0]new_packet_r;
reg prev_new_packet;
wire conerr;
wire shift;
reg rus;


assign shift = Func[0];


//assign dbg[0] = CLK_USB;
//assign dbg[1] = new_packet;
//assign dbg[2] = conerr;

ukp2key ukp2key_inst(
    .usbclk( CLK_USB ),		// 12MHz
    .usbrst_n( ~RESET ),	// reset
	.usb_dm( USB_DN ),
    .usb_dp( USB_DP ),
	.key0( key0 ), // modifiers
	.key1( key1 ), // pressed keys 1-6
	.key2( key2 ),
	.key3( key3 ),
	.key4( key4 ),
	.key5( key5 ),
	.key6( key6 ),
	.new_packet( new_packet ),
    .conerr( conerr )
);

always @( posedge CLK )begin
        new_packet_r[0] <= new_packet;
        new_packet_r[1] <= new_packet_r[0];
end

always @(posedge RESET or posedge CLK )begin
    if( RESET == 1'b1 )begin
        KeyMap0 <= 6'b111111;
        KeyMap1 <= 6'b111111;
        KeyMap2 <= 6'b111111;
        KeyMap3 <= 6'b111111;
        KeyMap4 <= 6'b111111;
        KeyMap5 <= 6'b111111;
        KeyMap6 <= 6'b111111;
        KeyMap7 <= 6'b111111;
        KeyMap8 <= 6'b111111;
        KeyMap9 <= 6'b111111;
        KeyMap10 <= 6'b111111;
        KeyMap11 <= 6'b111111;
        Func <= 6'b000000;
        rus <= 0;
    end else begin
        if( prev_new_packet != new_packet_r[1] )begin
            prev_new_packet <= new_packet_r[1];

            // reset out data
            KeyMap0 <= 6'b111111;
            KeyMap1 <= 6'b111111;
            KeyMap2 <= 6'b111111;
            KeyMap3 <= 6'b111111;
            KeyMap4 <= 6'b111111;
            KeyMap5 <= 6'b111111;
            KeyMap6 <= 6'b111111;
            KeyMap7 <= 6'b111111;
            KeyMap8 <= 6'b111111;
            KeyMap9 <= 6'b111111;
            KeyMap10 <= 6'b111111;
            KeyMap11 <= 6'b111111;
            Func <= 6'b000000;

            // modifiers
            if( key0 & BOTH_SHIFT )Func[0] <= 1'b1;
            if( (key0 & LEFT_SHIFT) && (key0 & LEFT_ALT) )begin
                KeyMap11[0] <= 1'b0;  // RUS/LAT
                rus <= ~rus;
            end

            // keys
            case( key1 )
                8'h1E:  KeyMap10[4] <= 1'b0;  // !1
                8'h1F:  if(shift)KeyMap3[1]<=1'b0;else KeyMap9[4]<=1'b0;  // @2
                8'h20:  KeyMap8[4] <= 1'b0;  // #3
                8'h21:  KeyMap7[4] <= 1'b0;  // $4
                8'h22:  KeyMap6[4] <= 1'b0;  // %5
                8'h23:  begin if(shift)begin
                            Func[0] <= 1'b0;    // remove shift
                            KeyMap10[1]<=1'b0;
                        end else
                            KeyMap5[4]<=1'b0; // ^6
                        end
                8'h24:  if(shift)KeyMap5[4]<=1'b0;else KeyMap4[4]<=1'b0;  // &7
                8'h25:  if(shift)KeyMap0[3]<=1'b0;else KeyMap3[4]<=1'b0;  // *8
                8'h26:  if(shift)KeyMap3[4]<=1'b0;else KeyMap2[4]<=1'b0;  // (9
                8'h27:  if(shift)KeyMap2[4]<=1'b0;else KeyMap1[4]<=1'b0;  // )0


                8'h04:  if(rus)KeyMap11[2]<=1'b0;else KeyMap8[2]<=1'b0;  // фA
                8'h05:  if(rus)KeyMap7[1]<=1'b0;else KeyMap4[1]<=1'b0;   // иB
                8'h06:  if(rus)KeyMap9[1]<=1'b0;else KeyMap10[3]<=1'b0;  // сC
                8'h07:  if(rus)KeyMap9[2]<=1'b0;else KeyMap3[2]<=1'b0;   // вD
                8'h08:  if(rus)KeyMap9[3]<=1'b0;else KeyMap7[3]<=1'b0;   // уE
                8'h09:  if(rus)KeyMap8[2]<=1'b0;else KeyMap11[2]<=1'b0;  // аF
                8'h0A:  if(rus)KeyMap7[2]<=1'b0;else KeyMap5[3]<=1'b0;   // пG
                8'h0B:  if(rus)KeyMap6[2]<=1'b0;else KeyMap1[3]<=1'b0;   // рH
                8'h0C:  if(rus)KeyMap4[3]<=1'b0;else KeyMap7[1]<=1'b0;   // шI
                8'h0D:  if(rus)KeyMap5[2]<=1'b0;else KeyMap11[3]<=1'b0;  // оJ
                8'h0E:  if(rus)KeyMap4[2]<=1'b0;else KeyMap8[3]<=1'b0;   // лK
                8'h0F:  if(rus)KeyMap3[2]<=1'b0;else KeyMap4[2]<=1'b0;   // дL

                8'h10:  if(rus)KeyMap5[1]<=1'b0;else KeyMap8[1]<=1'b0;   // ьM
                8'h11:  if(rus)KeyMap6[1]<=1'b0;else KeyMap6[3]<=1'b0;   // тN
                8'h12:  if(rus)KeyMap3[3]<=1'b0;else KeyMap5[2]<=1'b0;   // щO
                8'h13:  if(rus)KeyMap2[3]<=1'b0;else KeyMap7[2]<=1'b0;   // зP
                8'h14:  if(rus)KeyMap11[3]<=1'b0;else KeyMap11[1]<=1'b0; // йQ
                8'h15:  if(rus)KeyMap8[3]<=1'b0;else KeyMap6[2]<=1'b0;   // кR
                8'h16:  if(rus)KeyMap10[2]<=1'b0;else KeyMap9[1]<=1'b0;  // ыS
                8'h17:  if(rus)KeyMap7[3]<=1'b0;else KeyMap6[1]<=1'b0;   // еT
                8'h18:  if(rus)KeyMap5[3]<=1'b0;else KeyMap9[3]<=1'b0;   // гU
                8'h19:  if(rus)KeyMap8[1]<=1'b0;else KeyMap2[2]<=1'b0;   // мV
                8'h1A:  if(rus)KeyMap10[3]<=1'b0;else KeyMap9[2]<=1'b0;  // цW
                8'h1B:  if(rus)KeyMap10[1]<=1'b0;else KeyMap5[1]<=1'b0;  // чX
                8'h1C:  if(rus)KeyMap6[3]<=1'b0;else KeyMap10[2]<=1'b0;  // нY
                8'h1D:  if(rus)KeyMap11[1]<=1'b0;else KeyMap2[3]<=1'b0;  // яZ

                8'h28:  KeyMap0[0] <= 1'b0;  // enter - ВК
                //8'h29:  KeyMap5[] <= 1'b0;  // esc
                8'h2A:  KeyMap0[1] <= 1'b0;  // bsps - ЗБ
                8'h2B:  KeyMap3[0] <= 1'b0;  // tab - ПВ
                8'h2C:  KeyMap5[0] <= 1'b0;  // space
                8'h4F:  KeyMap2[0] <= 1'b0;  // right arrow
                8'h50:  KeyMap4[0] <= 1'b0;  // left arrow
                8'h51:  KeyMap8[0] <= 1'b0;  // down arrow
                8'h52:  KeyMap9[0] <= 1'b0;  // up arrow
                8'h4A:  KeyMap10[0] <= 1'b0;  // home
                8'h4D:  KeyMap1[0] <= 1'b0;  // end - ПС

                8'h3A:  KeyMap11[5] <= 1'b0; // F1 - F
                8'h3B:  KeyMap10[5] <= 1'b0; // F2 - HELP
                8'h3C:  KeyMap9[5] <= 1'b0;  // F3 - NEW
                8'h3D:  KeyMap8[5] <= 1'b0;  // F4 - LOAD
                8'h3E:  KeyMap7[5] <= 1'b0;  // F5 - SAVE
                8'h3F:  KeyMap6[5] <= 1'b0;  // F6 - RUN
                8'h40:  KeyMap5[5] <= 1'b0;  // F7 - STOP
                8'h41:  KeyMap4[5] <= 1'b0;  // F8 - CONT
                8'h42:  KeyMap3[5] <= 1'b0;  // F9 - EDIT
                8'h43:  KeyMap2[5] <= 1'b0;  // F10 - СФ
                8'h44:  KeyMap1[5] <= 1'b0;  // F11 - ТФ
                8'h45:  KeyMap0[5] <= 1'b0;  // F12 - НФ


                8'h2E:  if(shift)KeyMap0[4]<=1'b0;else KeyMap11[4] <= 1'b0;  // pc =+ sp =*
                8'h33:  if(rus)KeyMap2[2]<=1'b0;else if(shift)begin Func[0] <= 1'b0;KeyMap0[3]<=1'b0;end else KeyMap11[4] <= 1'b0;  // pc ;: sp ж;
                8'h2D:  KeyMap0[4] <= 1'b0;  // pc -_ sp -
                8'h34:  KeyMap1[2]<=1'b0;  // э
                8'h36:  if(rus)KeyMap4[1]<=1'b0;else KeyMap2[1] <= 1'b0;  // pc <, sp б
                8'h37:  if(rus)KeyMap3[1]<=1'b0;else KeyMap0[2] <= 1'b0;  // pc >. sp ю
                8'h31:  KeyMap1[2]<=1'b0;  // |
                8'h38:  KeyMap1[1]<=1'b0;  // ?
                8'h2F:  if(rus)KeyMap1[3]<=1'b0;else KeyMap4[3] <= 1'b0;  // pc [ sp х
                8'h30:  if(rus)KeyMap5[1]<=1'b0;else KeyMap3[3] <= 1'b0;  // pc ] sp ъ

                8'h4C:  begin if( (key0 & BOTH_CTRL) && (key0 & BOTH_ALT) ) Func[1]<=1'b1; end// del
            endcase
        end
    end
end

endmodule