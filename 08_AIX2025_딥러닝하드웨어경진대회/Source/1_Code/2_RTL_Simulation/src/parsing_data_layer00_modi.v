module parsing_data_layer00 (
    input clk,
    input rstn,
	input iStart,
	input i_fromYolo,

	output[15:0] oCs, // chip enable

	output[8:0] oAddr0,
	output[8:0] oAddr1,
	output[8:0] oAddr2,
	output[8:0] oAddr3,
	output[8:0] oAddr4,
	output[8:0] oAddr5,
	output[8:0] oAddr6,
	output[8:0] oAddr7,
	output[8:0] oAddr8,
	output[8:0] oAddr9,
	output[8:0] oAddr10,
	output[8:0] oAddr11,
	output[8:0] oAddr12,
	output[8:0] oAddr13,
	output[8:0] oAddr14,
	output[8:0] oAddr15,

	input [127:0] iData0	, //from bram data
	input [127:0] iData1,
	input [127:0] iData2,
	input [127:0] iData3,
	input [127:0] iData4,
	input [127:0] iData5,
	input [127:0] iData6,
	input [127:0] iData7,
	input [127:0] iData8,
	input [127:0] iData9,
	input [127:0] iData10,
	input [127:0] iData11,
	input [127:0] iData12,
	input [127:0] iData13,
	input [127:0] iData14,
	input [127:0] iData15,

	output [7:0] oDin0_0,
	output [7:0] oDin0_1,
	output [7:0] oDin0_2,
	output [7:0] oDin0_3,
	output [7:0] oDin0_4,
	output [7:0] oDin0_5,
	output [7:0] oDin0_6,
	output [7:0] oDin0_7,
	output [7:0] oDin0_8,
	output [7:0] oDin0_9,
	output [7:0] oDin0_10,
	output [7:0] oDin0_11,
	output [7:0] oDin0_12,
	output [7:0] oDin0_13,
	output [7:0] oDin0_14,
	output [7:0] oDin0_15,

	output [7:0] oDin1_0,
	output [7:0] oDin1_1,
	output [7:0] oDin1_2,
	output [7:0] oDin1_3,
	output [7:0] oDin1_4,
	output [7:0] oDin1_5,
	output [7:0] oDin1_6,
	output [7:0] oDin1_7,
	output [7:0] oDin1_8,
	output [7:0] oDin1_9,
	output [7:0] oDin1_10,
	output [7:0] oDin1_11,
	output [7:0] oDin1_12,
	output [7:0] oDin1_13,
	output [7:0] oDin1_14,
	output [7:0] oDin1_15,

	output [7:0] oDin2_0,
	output [7:0] oDin2_1,
	output [7:0] oDin2_2,
	output [7:0] oDin2_3,
	output [7:0] oDin2_4,
	output [7:0] oDin2_5,
	output [7:0] oDin2_6,
	output [7:0] oDin2_7,
	output [7:0] oDin2_8,
	output [7:0] oDin2_9,
	output [7:0] oDin2_10,
	output [7:0] oDin2_11,
	output [7:0] oDin2_12,
	output [7:0] oDin2_13,
	output [7:0] oDin2_14,
	output [7:0] oDin2_15,

	output oMac_vld,
	output oColEnd
);

localparam MAXCOL = 128;//256/2 -1
localparam MAXROW = 127;

localparam ST_IDLE         = 3'b000,
		   ST_ROW0         = 3'b001,
		   ST_ROW_ODD      = 3'b010,
		   ST_ROW_EVEN     = 3'b011,
		   ST_ROW_END      = 3'b100,
		   ST_COL_END      = 3'b101;//for sync axi this state acess all state except IDLE

		   
parameter windowDelay = 30;//rcnt increase until this value
parameter windowDelayWidth = 5;//rcnt adding log2(windowDelay))+1
parameter ACC_DELAY = 0;
parameter SPLIT_DELAY = windowDelay - ACC_DELAY;
parameter SPLIT_CNT = 33;
parameter SPLIT_CNT_WIDTH = 5;

parameter DATA_WIDTH = 32;
/*row change Delay*/
parameter COL_SYNC = windowDelay+1;//row change => delay clock
parameter COL_SYNC_WIDTH = 7;//log2(COL_SYNC) + 1

reg[windowDelayWidth - 1:0] rCnt_delay;

reg [COL_SYNC_WIDTH-1 :0] rColSyncDelay;

reg rEndOfColState;


reg rCol_toggle;//2 count

reg [2:0] rCurState;
reg [2:0] rNxtState;

reg [7:0] rRow, rCol;

reg [8:0] rAddr[0:15];

reg [127:0] r_data[0:15];

reg rRow_toggle1;
reg rRow_toggle2;

reg [1:0] rPrevState;

//-----------------
/*wire declartion*/
//----------------
wire wCol_end;
wire wRow_end;

reg [15:0] wCs;

reg [DATA_WIDTH-1:0] woDin[0:15];


//------------------------------------------------
// FSM
//--------------------------------------------------
always @(posedge clk, negedge rstn) begin
    if(!rstn) begin
       rCurState <= ST_IDLE;
    end
    else begin
        rCurState <= rNxtState;
    end
end
always @(*) begin
    case(rCurState)
		ST_IDLE: begin
			if(iStart == 1'b1) rNxtState <= ST_ROW0;
			else rNxtState <= ST_IDLE;
		end
		ST_ROW0: begin
			if(wCol_end) rNxtState <= ST_COL_END;
			else rNxtState <= ST_ROW0;
		end
		ST_ROW_ODD: begin
			if(wCol_end) rNxtState <= ST_COL_END;
			else rNxtState <= ST_ROW_ODD;
		end
		ST_ROW_EVEN: begin
			if(wCol_end) rNxtState <= ST_COL_END;
			else rNxtState <= ST_ROW_EVEN;
		end
		ST_ROW_END: begin
			if(wCol_end) rNxtState <= ST_COL_END;
			else rNxtState <= ST_ROW_END;
		end
		ST_COL_END: begin
			if(rEndOfColState) begin
				case (rPrevState)
					2'b00 : rNxtState <= ST_ROW_ODD;
					2'b01 : rNxtState <= ST_ROW_EVEN;
					2'b10 : rNxtState <= ST_ROW_ODD;
					2'b11 : rNxtState <= ST_IDLE;
				endcase
				if(wRow_end) begin
					rNxtState <= ST_ROW_END;
				end
			end
			else begin
				rNxtState <= ST_COL_END;
			end
		end
		default :
			rNxtState <= ST_IDLE;
    endcase            
end

////////////////
/* adressing signal1 chip select lsb = 0bram msb = 15bram*/ 
//////////////
always @(*) begin
	case(rCurState)
	ST_ROW0: begin
		if(rCol == 0) wCs = 16'b0000_0111_0111_0111;
		else wCs = 16'h0fff; 
	end
	ST_ROW_ODD: begin
		if(rCol == 0) wCs = 16'b0111_0111_0111_0111;
		else wCs = 16'hffff; 
	end
	ST_ROW_EVEN: begin
		if(rCol == 0) wCs = 16'b0111_0111_0111_0111;
		else wCs = 16'hffff; 
	end
	ST_ROW_END: begin
		if(rCol == 0) wCs = 16'b0111_0111_0111_0000;
		else wCs = 16'hfff0; 
	end
	/*
	ST_IDLE: wCs = 16'b0000_0111_0111_0111;
	ST_COL_END : wCs = 16'b0111_0111_0111_0111;
	*/
	endcase  
	
end

integer i;
////////////////
// adressing register 
////////////////
always @(posedge clk, negedge rstn) begin
	if(!rstn) begin
		for(i=0;i<16;i=i+1) begin
			rAddr[i] <= 9'd0;
		end
		rRow_toggle1 <= 1'b0;//64
		rRow_toggle2 <= 1'b0;//0 start
		rPrevState <= 2'b0;
	end
	else if(iStart && (rCurState != ST_COL_END))begin
		case(rCurState)
			ST_ROW0: begin
				if(wCol_end) begin
					for(i=4;i<16;i=i+1) begin
						rAddr[i] <= 9'd0;
					end
					for(i=0;i<4;i=i+1) begin
						rAddr[i] <= 9'd64;
					end
					rPrevState <= 2'b00;
				end
			end
			ST_ROW_ODD: begin
				if(wCol_end) begin
					rPrevState <= 2'b01;
					if(rRow_toggle1) begin
						for(i=0;i<12;i=i+1) begin
							rAddr[i] <= 9'd0;
						end
						for(i=12;i<16;i=i+1) begin
							rAddr[i] <= 9'd64;
						end
					end
					else begin
						for(i=0;i<12;i=i+1) begin
							rAddr[i] <= 9'd64;
						end
						for(i=12;i<16;i=i+1) begin
							rAddr[i] <= 9'd0;
						end
					end

					rRow_toggle1 <= rRow_toggle1 + 1'b1;
				end
			end
			ST_ROW_EVEN: begin
				if(wCol_end) begin
					rPrevState <= 2'b10;
					if(rRow_toggle2) begin
						for(i=4;i<16;i=i+1) begin
							rAddr[i] <= 9'd0;
						end
						for(i=0;i<4;i=i+1) begin
							rAddr[i] <= 9'd64;
						end
					end
					else begin
						for(i=4;i<16;i=i+1) begin
							rAddr[i] <= 9'd64;
						end
						for(i=0;i<4;i=i+1) begin
							rAddr[i] <= 9'd0;
						end
					end

					rRow_toggle2 <= rRow_toggle2 + 1'b1;
				end
			end
			ST_ROW_END : begin
				if(wCol_end) begin
					rPrevState <= 2'b11;
				end
			end
			default: rPrevState <= 2'b00;
    	endcase
		if(rCnt_delay == windowDelay)begin
			if(!(rCol == (MAXCOL -2))) begin
				if(rCol_toggle) begin
					rAddr[0] <= rAddr[0] + 1;
					rAddr[1] <= rAddr[1] + 1;
					rAddr[4] <= rAddr[4] + 1;
					rAddr[5] <= rAddr[5] + 1;
					rAddr[8] <= rAddr[8] + 1;
					rAddr[9] <= rAddr[9] + 1;
					rAddr[12] <= rAddr[12] + 1;
					rAddr[13] <= rAddr[13] + 1;
				end
				else begin
					rAddr[2] <= rAddr[2] + 1;
					rAddr[3] <= rAddr[3] + 1;
					rAddr[6] <= rAddr[6] + 1;
					rAddr[7] <= rAddr[7] + 1;
					rAddr[10] <= rAddr[10] + 1;
					rAddr[11] <= rAddr[11] + 1;
					rAddr[14] <= rAddr[14] + 1;
					rAddr[15] <= rAddr[15] + 1;
				end
			end
		end
	end 
end

reg r_ifromYoloDelay;

//COL_END STATE delay register 
always @(posedge clk, negedge rstn) begin
   if(!rstn) begin
      rEndOfColState <= 0;
      r_ifromYoloDelay <= 0;
   end
   else if(rCurState == ST_COL_END) begin
   //else if(rColSyncDelay == COL_SYNC) begin
      if(r_ifromYoloDelay && i_fromYolo) begin
         rEndOfColState <= 1'b1;
      end
      else begin
         rEndOfColState <= 0;
      end
      r_ifromYoloDelay <= 1'b1;
   end
   else begin
      rEndOfColState <= 0;
      r_ifromYoloDelay <= 0;
   end
end
/*
//COL_END STATE delay register 
always @(posedge clk, negedge rstn) begin
   if(!rstn) begin
      rColSyncDelay <= 0;
   end
   else if(rCurState == ST_COL_END) begin

      if(rColSyncDelay == COL_SYNC) begin
         rColSyncDelay <= COL_SYNC;
      end
      else begin
         rColSyncDelay <= rColSyncDelay + 1;
      end
      
   end
   else begin
		rColSyncDelay <= 0;
   end
end
*/
//Col row value calculate
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
       rCol<= 8'b0;
	   rRow <= 8'b0;
	   rCnt_delay <= 0;
	   rCol_toggle <= 0;
    end
    else if(iStart && (rCurState != ST_IDLE && rCurState != ST_COL_END)) begin
		if(wCol_end) begin
			rCol <= 0;
			rRow <= rRow + 1'b1;
		end
		else begin
			if(rCnt_delay == windowDelay)begin
				rCnt_delay <= 0;
				rCol <=  rCol + 1;
				rCol_toggle <= rCol_toggle + 1'b1;//toggle 1bit continuouly adding one 
			end
			else begin
				rCnt_delay <= rCnt_delay + 1'b1;
			end
		end
    end
end

assign wCol_end = (rCol == MAXCOL) ? 1'b1 : 1'b0;
assign wRow_end = (rRow == MAXROW) ? 1'b1 : 1'b0;


//////////////////////////////
// ZERO PADDING
//////////////////////////////
always @(*) begin
	//if(rCnt_delay > SPLIT_DELAY) begin
		case(rCurState)
			ST_ROW0: begin
				if(rCol == 0) begin //if col is 0
					for(i=0;i<4;i=i+1) begin
						woDin[i] <= 32'h0;
					end
					for(i=4;i<13;i=i+4) begin
						woDin[i] <= 32'h0;
					end
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin
						woDin[5][i+:8] <= r_data[0][i+:8];
						woDin[6][i+:8] <= r_data[1][i+:8];
						woDin[7][i+:8] <= r_data[2][i+:8];
						woDin[9][i+:8] <= r_data[4][i+:8];
						woDin[10][i+:8] <= r_data[5][i+:8];
						woDin[11][i+:8] <= r_data[6][i+:8];
						woDin[13][i+:8] <= r_data[8][i+:8];
						woDin[14][i+:8] <= r_data[9][i+:8];
						woDin[15][i+:8] <= r_data[10][i+:8];
					end
				
				end
				else if(rCol == (MAXCOL -1)) begin
					for(i=0;i<4;i=i+1) begin
						woDin[i] <= 32'h0;
					end
					for(i=7;i<16;i=i+4) begin
						woDin[i] <= 32'h0;
					end
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin
						woDin[4][i+:8] <= r_data[1][i+:8];
						woDin[5][i+:8] <= r_data[2][i+:8];
						woDin[6][i+:8] <= r_data[3][i+:8];
						woDin[8][i+:8] <= r_data[5][i+:8];
						woDin[9][i+:8] <= r_data[6][i+:8];
						woDin[10][i+:8] <= r_data[7][i+:8];
						woDin[12][i+:8] <= r_data[9][i+:8];
						woDin[13][i+:8] <= r_data[10][i+:8];
						woDin[14][i+:8] <= r_data[11][i+:8];
					end

				end
				else begin //if col is not 0
					for(i=0;i<4;i=i+1) begin
						woDin[i] <= 32'h0;
					end
					if(rCol_toggle) begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[4][i+:8] <= r_data[1][i+:8];
							woDin[5][i+:8] <= r_data[2][i+:8];
							woDin[6][i+:8] <= r_data[3][i+:8];
							woDin[7][i+:8] <= r_data[0][i+:8];

							woDin[8][i+:8] <= r_data[5][i+:8];
							woDin[9][i+:8] <= r_data[6][i+:8];
							woDin[10][i+:8] <= r_data[7][i+:8];
							woDin[11][i+:8] <= r_data[4][i+:8];

							woDin[12][i+:8] <= r_data[9][i+:8];
							woDin[13][i+:8] <= r_data[10][i+:8];
							woDin[14][i+:8] <= r_data[11][i+:8];
							woDin[15][i+:8] <= r_data[8][i+:8];
						end
					end
					else begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin
							woDin[4][i+:8] <= r_data[3][i+:8];
							woDin[5][i+:8] <= r_data[0][i+:8];
							woDin[6][i+:8] <= r_data[1][i+:8];
							woDin[7][i+:8] <= r_data[2][i+:8];

							woDin[8][i+:8] <= r_data[7][i+:8];
							woDin[9][i+:8] <= r_data[4][i+:8];
							woDin[10][i+:8] <= r_data[5][i+:8];
							woDin[11][i+:8] <= r_data[6][i+:8];

							woDin[12][i+:8] <= r_data[11][i+:8];
							woDin[13][i+:8] <= r_data[8][i+:8];
							woDin[14][i+:8] <= r_data[9][i+:8];
							woDin[15][i+:8] <= r_data[10][i+:8];
						end
					end
				end
			end
			ST_ROW_ODD: begin
				if(rCol == 0) begin //if col is 0
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
						woDin[0][i+:8] <= 8'b0;
						woDin[1][i+:8] <= r_data[4][i+:8];
						woDin[2][i+:8] <= r_data[5][i+:8];
						woDin[3][i+:8] <= r_data[6][i+:8];

						woDin[4][i+:8] <= 8'b0;
						woDin[5][i+:8] <= r_data[8][i+:8];
						woDin[6][i+:8] <= r_data[9][i+:8];
						woDin[7][i+:8] <= r_data[10][i+:8];

						woDin[8][i+:8] <= 8'b0;
						woDin[9][i+:8] <= r_data[12][i+:8];
						woDin[10][i+:8] <= r_data[13][i+:8];
						woDin[11][i+:8] <= r_data[14][i+:8];

						woDin[12][i+:8] <= 8'b0;
						woDin[13][i+:8] <= r_data[0][i+:8];
						woDin[14][i+:8] <= r_data[1][i+:8];
						woDin[15][i+:8] <= r_data[2][i+:8];

					end
				end
				else if(rCol == (MAXCOL -1)) begin
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
			
						woDin[0][i+:8] <= r_data[5][i+:8];
						woDin[1][i+:8] <= r_data[6][i+:8];
						woDin[2][i+:8] <= r_data[7][i+:8];
						woDin[3][i+:8] <= 8'b0;

						woDin[4][i+:8] <= r_data[9][i+:8];
						woDin[5][i+:8] <= r_data[10][i+:8];
						woDin[6][i+:8] <= r_data[11][i+:8];
						woDin[7][i+:8] <= 8'b0;

						woDin[11][i+:8] <= 8'b0;
						woDin[8][i+:8] <= r_data[13][i+:8];
						woDin[9][i+:8] <= r_data[14][i+:8];
						woDin[10][i+:8] <= r_data[15][i+:8];

						woDin[15][i+:8] <= 8'b0;
						woDin[12][i+:8] <= r_data[1][i+:8];
						woDin[13][i+:8] <= r_data[2][i+:8];
						woDin[14][i+:8] <= r_data[3][i+:8];

					end
				end
				else begin //if col is not 0
					if(rCol_toggle) begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[5][i+:8];
							woDin[1][i+:8] <= r_data[6][i+:8];
							woDin[2][i+:8] <= r_data[7][i+:8];
							woDin[3][i+:8] <= r_data[4][i+:8];

							woDin[4][i+:8] <= r_data[9][i+:8];
							woDin[5][i+:8] <= r_data[10][i+:8];
							woDin[6][i+:8] <= r_data[11][i+:8];
							woDin[7][i+:8] <= r_data[8][i+:8];

							woDin[8][i+:8] <= r_data[13][i+:8];
							woDin[9][i+:8] <= r_data[14][i+:8];
							woDin[10][i+:8] <= r_data[15][i+:8];
							woDin[11][i+:8] <= r_data[12][i+:8];

							woDin[12][i+:8] <= r_data[1][i+:8];
							woDin[13][i+:8] <= r_data[2][i+:8];
							woDin[14][i+:8] <= r_data[3][i+:8];
							woDin[15][i+:8] <= r_data[0][i+:8];

						end
						
					end
					else begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[7][i+:8];
							woDin[1][i+:8] <= r_data[4][i+:8];
							woDin[2][i+:8] <= r_data[5][i+:8];
							woDin[3][i+:8] <= r_data[6][i+:8];

							woDin[4][i+:8] <= r_data[11][i+:8];
							woDin[5][i+:8] <= r_data[8][i+:8];
							woDin[6][i+:8] <= r_data[9][i+:8];
							woDin[7][i+:8] <= r_data[10][i+:8];

							woDin[8][i+:8] <= r_data[15][i+:8];
							woDin[9][i+:8] <= r_data[12][i+:8];
							woDin[10][i+:8] <= r_data[13][i+:8];
							woDin[11][i+:8] <= r_data[14][i+:8];

							woDin[12][i+:8] <= r_data[3][i+:8];
							woDin[13][i+:8] <= r_data[0][i+:8];
							woDin[14][i+:8] <= r_data[1][i+:8];
							woDin[15][i+:8] <= r_data[2][i+:8];

						end
					end
				end
			end
			ST_ROW_EVEN: begin
				if(rCol == 0) begin //if col is 0
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
						woDin[0][i+:8] <= 8'b0;
						woDin[1][i+:8] <= r_data[12][i+:8];
						woDin[2][i+:8] <= r_data[13][i+:8];
						woDin[3][i+:8] <= r_data[14][i+:8];

						woDin[4][i+:8] <= 8'b0;
						woDin[5][i+:8] <= r_data[0][i+:8];
						woDin[6][i+:8] <= r_data[1][i+:8];
						woDin[7][i+:8] <= r_data[2][i+:8];

						woDin[8][i+:8] <= 8'b0;
						woDin[9][i+:8] <= r_data[4][i+:8];
						woDin[10][i+:8] <= r_data[5][i+:8];
						woDin[11][i+:8] <= r_data[6][i+:8];

						woDin[12][i+:8] <= 8'b0;
						woDin[13][i+:8] <= r_data[8][i+:8];
						woDin[14][i+:8] <= r_data[9][i+:8];
						woDin[15][i+:8] <= r_data[10][i+:8];

					end
				end
				else if(rCol == (MAXCOL -1)) begin
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
						woDin[3][i+:8] <= 8'b0;
						woDin[0][i+:8] <= r_data[13][i+:8];
						woDin[1][i+:8] <= r_data[14][i+:8];
						woDin[2][i+:8] <= r_data[15][i+:8];

						woDin[7][i+:8] <= 8'b0;
						woDin[4][i+:8] <= r_data[1][i+:8];
						woDin[5][i+:8] <= r_data[2][i+:8];
						woDin[6][i+:8] <= r_data[3][i+:8];

						woDin[11][i+:8] <= 8'b0;
						woDin[8][i+:8] <= r_data[5][i+:8];
						woDin[9][i+:8] <= r_data[6][i+:8];
						woDin[10][i+:8] <= r_data[7][i+:8];

						woDin[15][i+:8] <= 8'b0;
						woDin[12][i+:8] <= r_data[9][i+:8];
						woDin[13][i+:8] <= r_data[10][i+:8];
						woDin[14][i+:8] <= r_data[11][i+:8];
					end
				end
				else begin //if col is not 0
					if(rCol_toggle) begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[13][i+:8];
							woDin[1][i+:8] <= r_data[14][i+:8];
							woDin[2][i+:8] <= r_data[15][i+:8];
							woDin[3][i+:8] <= r_data[12][i+:8];

							woDin[4][i+:8] <= r_data[1][i+:8];
							woDin[5][i+:8] <= r_data[2][i+:8];
							woDin[6][i+:8] <= r_data[3][i+:8];
							woDin[7][i+:8] <= r_data[0][i+:8];

							woDin[8][i+:8] <= r_data[5][i+:8];
							woDin[9][i+:8] <= r_data[6][i+:8];
							woDin[10][i+:8] <= r_data[7][i+:8];
							woDin[11][i+:8] <= r_data[4][i+:8];

							woDin[12][i+:8] <= r_data[9][i+:8];
							woDin[13][i+:8] <= r_data[10][i+:8];
							woDin[14][i+:8] <= r_data[11][i+:8];
							woDin[15][i+:8] <= r_data[8][i+:8];
						end
					end
					else begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[7][i+:8];
							woDin[1][i+:8] <= r_data[4][i+:8];
							woDin[2][i+:8] <= r_data[5][i+:8];
							woDin[3][i+:8] <= r_data[6][i+:8];

							woDin[4][i+:8] <= r_data[11][i+:8];
							woDin[5][i+:8] <= r_data[8][i+:8];
							woDin[6][i+:8] <= r_data[9][i+:8];
							woDin[7][i+:8] <= r_data[10][i+:8];

							woDin[8][i+:8] <= r_data[15][i+:8];
							woDin[9][i+:8] <= r_data[12][i+:8];
							woDin[10][i+:8] <= r_data[13][i+:8];
							woDin[11][i+:8] <= r_data[14][i+:8];

							woDin[12][i+:8] <= r_data[3][i+:8];
							woDin[13][i+:8] <= r_data[0][i+:8];
							woDin[14][i+:8] <= r_data[1][i+:8];
							woDin[15][i+:8] <= r_data[2][i+:8];
						end
					end
				end
			end
			ST_ROW_END: begin
				if(rCol == 0) begin //if col is 0
					for(i=12;i<16;i=i+1) begin
						woDin[i]<= 32'h0;
					end
					for(i=0;i<9;i=i+4) begin//0 4 8
						woDin[i] <= 32'h0;
					end
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
						woDin[1][i+:8] <= r_data[4][i+:8];
						woDin[2][i+:8] <= r_data[5][i+:8];
						woDin[3][i+:8] <= r_data[6][i+:8];

						woDin[5][i+:8] <= r_data[8][i+:8];
						woDin[6][i+:8] <= r_data[9][i+:8];
						woDin[7][i+:8] <= r_data[10][i+:8];

						woDin[9][i+:8] <= r_data[12][i+:8];
						woDin[10][i+:8] <= r_data[13][i+:8];
						woDin[11][i+:8] <= r_data[14][i+:8];
					end
				end
				else if(rCol == (MAXCOL -1)) begin
					for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
						woDin[0][i+:8] <= r_data[5][i+:8];
						woDin[1][i+:8] <= r_data[6][i+:8];
						woDin[2][i+:8] <= r_data[7][i+:8];
						woDin[3][i+:8] <= 8'b0;
						
						woDin[4][i+:8] <= r_data[9][i+:8];
						woDin[5][i+:8] <= r_data[10][i+:8];
						woDin[6][i+:8] <= r_data[11][i+:8];
						woDin[7][i+:8] <= 8'b0;

						woDin[8][i+:8] <= r_data[13][i+:8];
						woDin[9][i+:8] <= r_data[14][i+:8];
						woDin[10][i+:8] <= r_data[15][i+:8];
						woDin[11][i+:8] <= 8'b0;
					end
					for(i=12;i<16;i=i+1) begin//0 4 8
						woDin[i] <= 32'h0;
					end
				end
				else begin //if col is not 0
					for(i=12;i<16;i=i+1) begin
						woDin[i] <= 32'h0;
					end
					if(rCol_toggle) begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[5][i+:8];
							woDin[1][i+:8] <= r_data[6][i+:8];
							woDin[2][i+:8] <= r_data[7][i+:8];
							woDin[3][i+:8] <= r_data[4][i+:8];

							woDin[4][i+:8] <= r_data[9][i+:8];
							woDin[5][i+:8] <= r_data[10][i+:8];
							woDin[6][i+:8] <= r_data[11][i+:8];
							woDin[7][i+:8] <= r_data[8][i+:8];

							woDin[8][i+:8] <= r_data[13][i+:8];
							woDin[9][i+:8] <= r_data[14][i+:8];
							woDin[10][i+:8] <= r_data[15][i+:8];
							woDin[11][i+:8] <= r_data[12][i+:8];

						end
					end
					else begin
						for(i = 0; i<DATA_WIDTH; i=i+8 ) begin // 4ea rgb0 slicing 
							woDin[0][i+:8] <= r_data[7][i+:8];
							woDin[1][i+:8] <= r_data[4][i+:8];
							woDin[2][i+:8] <= r_data[5][i+:8];
							woDin[3][i+:8] <= r_data[6][i+:8];

							woDin[4][i+:8] <= r_data[11][i+:8];
							woDin[5][i+:8] <= r_data[8][i+:8];
							woDin[6][i+:8] <= r_data[9][i+:8];
							woDin[7][i+:8] <= r_data[10][i+:8];

							woDin[8][i+:8] <= r_data[15][i+:8];
							woDin[9][i+:8] <= r_data[12][i+:8];
							woDin[10][i+:8] <= r_data[13][i+:8];
							woDin[11][i+:8] <= r_data[14][i+:8];
						end
					end
				end
			end
		endcase
	//end
end


always @(posedge clk, negedge rstn) begin //name
	if(!rstn) begin
		for(i=0;i<16;i=i+1) begin
			r_data[i] <= 0;
		end
	end
	else if(iStart && (rCurState != ST_COL_END)) begin
		
		r_data[0] <= iData0;
		r_data[1] <= iData1;
		r_data[2] <= iData2;
		r_data[3] <= iData3;
		r_data[4] <= iData4;
		r_data[5] <= iData5;
		r_data[6] <= iData6;
		r_data[7] <= iData7;
		r_data[8] <= iData8;
		r_data[9] <= iData9;
		r_data[10] <= iData10;
		r_data[11] <= iData11;
		r_data[12] <= iData12;
		r_data[13] <= iData13;
		r_data[14] <= iData14;
		r_data[15] <= iData15;	

	end
end

assign oCs = wCs;
/*
assign oMac_vld = ((rCnt_delay > 4) || (rCurState == ST_COL_END && (rColSyncDelay>4 && rColSyncDelay < COL_SYNC) ))
               ? 1'b1 : 1'b0;//starting split 
*/
assign oMac_vld = (rCnt_delay > 4)? 1'b1 : 1'b0;//starting split 

assign oAddr0 = rAddr[0];
assign oAddr1 = rAddr[1];
assign oAddr2 = rAddr[2];
assign oAddr3 = rAddr[3];
assign oAddr4 = rAddr[4];
assign oAddr5 = rAddr[5];
assign oAddr6 = rAddr[6];
assign oAddr7 = rAddr[7];
assign oAddr8 = rAddr[8];
assign oAddr9 = rAddr[9];
assign oAddr10 = rAddr[10];
assign oAddr11 = rAddr[11];
assign oAddr12 = rAddr[12];
assign oAddr13 = rAddr[13];
assign oAddr14 = rAddr[14];
assign oAddr15 = rAddr[15];

assign oDin0_0 = woDin[0][0+:8];
assign oDin0_1 = woDin[1][0+:8];
assign oDin0_2 = woDin[2][0+:8];
assign oDin0_3 = woDin[3][0+:8]; 
assign oDin0_4 = woDin[4][0+:8]; 
assign oDin0_5 = woDin[5][0+:8]; 
assign oDin0_6 = woDin[6][0+:8]; 
assign oDin0_7 = woDin[7][0+:8]; 
assign oDin0_8 = woDin[8][0+:8]; 
assign oDin0_9 = woDin[9][0+:8]; 
assign oDin0_10 = woDin[10][0+:8]; 
assign oDin0_11 = woDin[11][0+:8]; 
assign oDin0_12 = woDin[12][0+:8]; 
assign oDin0_13 = woDin[13][0+:8]; 
assign oDin0_14 = woDin[14][0+:8]; 
assign oDin0_15 = woDin[15][0+:8]; 

assign oDin1_0 = woDin[0][8+:8];
assign oDin1_1 = woDin[1][8+:8];
assign oDin1_2 = woDin[2][8+:8];
assign oDin1_3 = woDin[3][8+:8]; 
assign oDin1_4 = woDin[4][8+:8]; 
assign oDin1_5 = woDin[5][8+:8]; 
assign oDin1_6 = woDin[6][8+:8]; 
assign oDin1_7 = woDin[7][8+:8]; 
assign oDin1_8 = woDin[8][8+:8]; 
assign oDin1_9 = woDin[9][8+:8]; 
assign oDin1_10 = woDin[10][8+:8]; 
assign oDin1_11 = woDin[11][8+:8]; 
assign oDin1_12 = woDin[12][8+:8]; 
assign oDin1_13 = woDin[13][8+:8]; 
assign oDin1_14 = woDin[14][8+:8]; 
assign oDin1_15 = woDin[15][8+:8]; 

assign oDin2_0 = woDin[0][16+:8];
assign oDin2_1 = woDin[1][16+:8];
assign oDin2_2 = woDin[2][16+:8];
assign oDin2_3 = woDin[3][16+:8]; 
assign oDin2_4 = woDin[4][16+:8]; 
assign oDin2_5 = woDin[5][16+:8]; 
assign oDin2_6 = woDin[6][16+:8]; 
assign oDin2_7 = woDin[7][16+:8]; 
assign oDin2_8 = woDin[8][16+:8]; 
assign oDin2_9 = woDin[9][16+:8]; 
assign oDin2_10 = woDin[10][16+:8]; 
assign oDin2_11 = woDin[11][16+:8]; 
assign oDin2_12 = woDin[12][16+:8]; 
assign oDin2_13 = woDin[13][16+:8]; 
assign oDin2_14 = woDin[14][16+:8]; 
assign oDin2_15 = woDin[15][16+:8]; 

//assign oColEnd = (rColSyncDelay == (COL_SYNC)) ? 1'b1 : 1'b0;
assign oColEnd = (rCurState == ST_COL_END) ? 1'b1 : 1'b0;
endmodule