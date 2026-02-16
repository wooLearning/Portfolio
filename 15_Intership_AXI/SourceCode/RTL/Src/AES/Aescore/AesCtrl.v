`timescale 1ns/10ps

module AesCrtl( //non verificate code complited
  
  input iClk,
  input iRsn,

  input iStAes,

  output oInitRoundFlag,
  output oFstRoundFlag,
  output oMidRoundFlag,
  output oLstRoundFlag,

  output oAesDone
);

  parameter p_Idle      = 3'b000,
            p_InitRound = 3'b001,
            p_FstRound  = 3'b010,
            p_MidRound  = 3'b011,
            p_LstRound  = 3'b100,
            p_AesDone   = 3'b101;

reg[2:0] rCurState;
reg[2:0] rNxtState;
reg[3:0] rNumOfRound;

/*FSM*///Part 2 next state decision
  always @(posedge iClk) begin
    if(!iRsn)
      rCurState <= p_Idle;
    else
      rCurState <= rNxtState[2:0];
  end

  always @(*) begin
    case (rCurState)
      p_Idle: begin
        if(iStAes == 1'b1) rNxtState <= p_InitRound;
        else rNxtState <= p_Idle;
      end
      p_InitRound: begin 
        rNxtState <= p_FstRound;
      end
      p_FstRound: begin
        rNxtState <= p_MidRound;
      end
      p_MidRound: begin
        if(rNumOfRound == 4'h9) rNxtState <= p_LstRound;
        else rNxtState <= p_MidRound;
      end 
      p_LstRound: begin
        rNxtState <= p_AesDone;
      end
      p_AesDone: begin
        rNxtState <= p_Idle;
      end
      default: rNxtState <= p_Idle;
    endcase
  end

//part2 combinational logic
always @(posedge iClk) begin
  if(!iRsn) begin
    rNumOfRound <= 4'h1;
  end
  else if(rCurState == p_FstRound) begin
    rNumOfRound[3:0] <= rNumOfRound[3:0] + 1'b1;
  end
  else if(rCurState == p_MidRound) begin
    rNumOfRound[3:0] <= rNumOfRound[3:0] + 1'b1;
  end
  else if(rCurState == p_AesDone) begin
    rNumOfRound <= 4'b0;
  end
end

//part3 output logic

assign oInitRoundFlag = (rCurState == p_InitRound) ? 1'b1 : 1'b0;
assign oFstRoundFlag = (rCurState == p_FstRound) ? 1'b1 : 1'b0;
assign oMidRoundFlag = (rCurState == p_MidRound) ? 1'b1 : 1'b0;
assign oLstRoundFlag = (rCurState == p_LstRound) ? 1'b1 : 1'b0;
assign oAesDone = (rCurState == p_AesDone) ? 1'b1 : 1'b0;

endmodule
