module ps2kbd(
	inout   ps2_kb_dat,
	inout   ps2_kb_clk,	

    input	wire		clk,         //clock 14 или более Мгц
    input	wire		reset,       //вход сброса контроллера.
output dbg,
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

reg     ps2rden;
wire	[7:0]ps2q;	
wire	ps2dsr;
reg		[3:0]state = 0;
reg		[7:0]zx_kb;
reg		ex_code	= 0;
reg		numlock;
reg		press_release;
reg		strobe;
wire shift = Func[0];
reg rus, ctrl, alt;

assign dbg = rus;

always @( posedge clk )begin
	if( reset )begin
		state			<= 0;
	end	else begin
		case( state )
		0: begin
			if( ps2dsr )begin
					ps2rden <= 1;
					state 	<= 1;
					end
			end
		1:	begin
				state <= 2;
				ps2rden <= 0;
			end
		2:	begin
				ps2rden <= 0;
				if( ps2q == 8'hF0 )begin
					state <= 6;
				end	else
                    if( ps2q == 8'hE0 )begin
						ex_code	<= 1;
						state <= 0;
					end	else begin
						state <= 4;
					end
			end
		4:	begin
			if ((ps2q == 8'h12) && ex_code) begin
				ex_code <= 0;
				state <= 0;
			end	else
				zx_kb <= ps2q;
				press_release	<= 1'b0;    // press
				strobe	<=	1'b1;
                state <= 5;
			end
		5:	begin
			strobe	<=	1'b0;
			state	<=	0;
			ex_code <=  0;
			end
			
		6:	begin
				if (ps2dsr) begin
					ps2rden <= 1;
					state <= 7;
				end
			end
			
		7:	begin
				ps2rden <= 0;
				state <= 8;
			end
			
		8:	begin
			if (ps2q == 8'hE0) begin
				ex_code <= 1'b1;
				state <=  6;
				end
			else	begin	
					state <= 9;
					end
			end
		9:	begin
				if ((ps2q == 8'h12) && ex_code) begin
					ex_code <= 0;
					state <= 6;
				end
			else
				zx_kb <= ps2q;
				press_release	<= 1'b1;    // unpress
				strobe	<=	1'b1;
				state <= 10;
			end
		10:	begin
			ex_code <=  0;
			strobe	<=	1'b0;
			state	<=	0;
			end
        endcase
    end
end


always	@( posedge	clk )begin
	if( reset )begin
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
        ctrl <= 0;
        alt <= 0;
	end	else begin
				if (strobe) begin
					case ({ex_code, zx_kb[7:0]})

		      9'h012,9'h059: begin
                                Func[0] <= ~press_release;             // Shift
                                if( alt )begin
                                    KeyMap11[0] <= press_release;       // RUS/LAT
                                    if( press_release ) rus <= ~rus;
                                end
                            end
			  9'h111,9'h011: begin if( shift )begin                 // Alt
                                KeyMap11[0] <= press_release;       // RUS/LAT
                                if( press_release ) rus <= ~rus;
                            end
                                alt <= ~press_release;
                            end
              9'h014,9'h114: ctrl <= ~press_release;    // Ctrl
                    9'h171:	begin if( ctrl && alt ) Func[1]<=~press_release; end // del

					9'h007:	KeyMap0[5] <= press_release; // F12
					9'h078:	KeyMap1[5] <= press_release; // F11
					9'h009:	KeyMap2[5] <= press_release; // F10
					9'h001:	KeyMap3[5] <= press_release; // F9
					9'h00a:	KeyMap4[5] <= press_release; // F8
					9'h083:	KeyMap5[5] <= press_release; // F7
					9'h00b:	KeyMap6[5] <= press_release; // F6
					9'h003:	KeyMap7[5] <= press_release; // F5
					9'h00c:	KeyMap8[5] <= press_release; // F4
					9'h004:	KeyMap9[5] <= press_release; // F3
					9'h006:	KeyMap10[5] <= press_release; // F2
                    9'h005:	KeyMap11[5] <= press_release; // F1

    		  9'h016,9'h069: KeyMap10[4] <= press_release;  // !1
			  9'h01e,9'h072: if( shift ) KeyMap3[1] <= press_release; else KeyMap9[4] <= press_release;  // @2
			  9'h026,9'h07a: KeyMap8[4] <= press_release;  // #3
					 9'h025: KeyMap7[4] <= press_release;  // $4
					 9'h02e: KeyMap6[4] <= press_release;  // %5
					 9'h036: //begin if( shift )begin
                            //Func[0] <= 1'b0;    // remove shift
                            //KeyMap10[1] <= press_release;// ^
                        //end else
                            KeyMap5[4] <= press_release; // 6
                        //end
			  9'h03d,9'h06c: if( shift )KeyMap5[4] <= press_release; else KeyMap4[4] <= press_release;  // &7
					 9'h03e: if( shift )KeyMap0[3] <= press_release; else KeyMap3[4] <= press_release;  // *8
    		  9'h046,9'h07d: if( shift )KeyMap3[4] <= press_release; else KeyMap2[4] <= press_release;  // (9
		      9'h045,9'h070: if( shift )KeyMap2[4] <= press_release; else KeyMap1[4] <= press_release;  // )0


                9'h1C:  if(rus)KeyMap11[2]<=press_release;else KeyMap8[2]<=press_release;  // фA
                9'h32:  if(rus)KeyMap7[1]<=press_release;else KeyMap4[1]<=press_release;   // иB
                9'h21:  if(rus)KeyMap9[1]<=press_release;else KeyMap10[3]<=press_release;  // сC
                9'h23:  if(rus)KeyMap9[2]<=press_release;else KeyMap3[2]<=press_release;   // вD
                9'h24:  if(rus)KeyMap9[3]<=press_release;else KeyMap7[3]<=press_release;   // уE
                9'h2b:  if(rus)KeyMap8[2]<=press_release;else KeyMap11[2]<=press_release;  // аF
                9'h34:  if(rus)KeyMap7[2]<=press_release;else KeyMap5[3]<=press_release;   // пG
                9'h33:  if(rus)KeyMap6[2]<=press_release;else KeyMap1[3]<=press_release;   // рH
                9'h43:  if(rus)KeyMap4[3]<=press_release;else KeyMap7[1]<=press_release;   // шI
                9'h3B:  if(rus)KeyMap5[2]<=press_release;else KeyMap11[3]<=press_release;  // оJ
                9'h42:  if(rus)KeyMap4[2]<=press_release;else KeyMap8[3]<=press_release;   // лK
                9'h4B:  if(rus)KeyMap3[2]<=press_release;else KeyMap4[2]<=press_release;   // дL

                9'h3A:  if(rus)KeyMap5[1]<=press_release;else KeyMap8[1]<=press_release;   // ьM
                9'h31:  if(rus)KeyMap6[1]<=press_release;else KeyMap6[3]<=press_release;   // тN
                9'h44:  if(rus)KeyMap3[3]<=press_release;else KeyMap5[2]<=press_release;   // щO
                9'h4D:  if(rus)KeyMap2[3]<=press_release;else KeyMap7[2]<=press_release;   // зP
                9'h15:  if(rus)KeyMap11[3]<=press_release;else KeyMap11[1]<=press_release; // йQ
                9'h2D:  if(rus)KeyMap8[3]<=press_release;else KeyMap6[2]<=press_release;   // кR
                9'h1B:  if(rus)KeyMap10[2]<=press_release;else KeyMap9[1]<=press_release;  // ыS
                9'h2C:  if(rus)KeyMap7[3]<=press_release;else KeyMap6[1]<=press_release;   // еT
                9'h3C:  if(rus)KeyMap5[3]<=press_release;else KeyMap9[3]<=press_release;   // гU
                9'h2A:  if(rus)KeyMap8[1]<=press_release;else KeyMap2[2]<=press_release;   // мV
                9'h1D:  if(rus)KeyMap10[3]<=press_release;else KeyMap9[2]<=press_release;  // цW
                9'h22:  if(rus)KeyMap10[1]<=press_release;else KeyMap5[1]<=press_release;  // чX
                9'h35:  if(rus)KeyMap6[3]<=press_release;else KeyMap10[2]<=press_release;  // нY
                9'h1A:  if(rus)KeyMap11[1]<=press_release;else KeyMap2[3]<=press_release;  // яZ

//                9'h55:  if(shift)KeyMap0[4]<=press_release;else KeyMap11[4] <= press_release;  // pc =+ sp =*
                9'h55:  if(shift)KeyMap11[4] <= press_release;else KeyMap0[4]<=press_release;  // pc =+ sp =*
                9'h4C:  if(rus)KeyMap2[2]<=press_release;else if(shift)begin Func[0] <= press_release;KeyMap0[3]<=press_release;end else KeyMap11[4] <= press_release;  // pc ;: sp ж;
                9'h4E:  KeyMap0[4] <= press_release;  // pc -_ sp -
                9'h52:  KeyMap1[2]<=press_release;  // э
                9'h41:  if(rus)KeyMap4[1]<=press_release;else KeyMap2[1] <= press_release;  // pc <, sp б
                9'h49:  if(rus)KeyMap3[1]<=press_release;else KeyMap0[2] <= press_release;  // pc >. sp ю
                9'h5D:  KeyMap1[2]<=press_release;  // |
                9'h4A:  KeyMap1[1]<=press_release;  // ?
                9'h54:  if(rus)KeyMap1[3]<=press_release;else KeyMap4[3] <= press_release;  // pc [ sp х
                9'h5B:  if(rus)KeyMap5[1]<=press_release;else KeyMap3[3] <= press_release;  // pc ] sp ъ


					9'h029:	KeyMap5[0]	<= press_release; // Space
                    9'h15a, 9'h05a:	KeyMap0[0] <= press_release; //Enter
                9'h66:  KeyMap0[1] <= press_release;  // bsps - ЗБ
                9'h0D:  KeyMap3[0] <= press_release;  // tab - ПВ
                9'h174:  KeyMap2[0] <= press_release;  // right arrow
                9'h16B:  KeyMap4[0] <= press_release;  // left arrow
                9'h172:  KeyMap8[0] <= press_release;  // down arrow
                9'h175:  KeyMap9[0] <= press_release;  // up arrow
                9'h16C:  KeyMap10[0] <= press_release;  // home
                9'h169:  KeyMap1[0] <= press_release;  // end - ПС

						//8'h7e:          res_key     	<= 1'b0;        //Scroll Lock
//						8'h77:			numlock			<= ~numlock;
					endcase
				end
	end
end


ps2_keyboard ps2_keyboard(
	.clk							(clk),
	.reset							(reset),
	.ps2_clk_i						(ps2_kb_clk),
	.ps2_data_i						(ps2_kb_dat),
	.rx_released					(),
	.rx_shift_key_on				(),
	.rx_scan_code					(ps2q),
	.rx_ascii						(),
	.rx_data_ready					(ps2dsr),  
	.rx_read						(ps2rden),
    .tx_data(8'h00), .tx_write(1'b0), .translate(1'b0), .ps2_clk_en_o_(),.ps2_data_en_o_()
  );
endmodule