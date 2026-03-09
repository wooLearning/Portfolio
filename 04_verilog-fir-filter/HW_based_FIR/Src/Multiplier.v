/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Multiplier.v
  - Description      : Multiplexer
  - Owner            : Dongjun.Joo
  - Revision history : 1) 2024.11.21 : Initial release AccumulatorAccumulator
*******************************************************************/

module Multiplier (
    input iEnMul,
    input iRsn,
    input iClk12M,
    input  signed [15:0] iCoeff,

    input  signed [ 2:0] iDelay_0,
    input  signed [ 2:0] iDelay_1,
    input  signed [ 2:0] iDelay_2,
    input  signed [ 2:0] iDelay_3,
    input  signed [ 2:0] iDelay_4,
    input  signed [ 2:0] iDelay_5,
    input  signed [ 2:0] iDelay_6,
    input  signed [ 2:0] iDelay_7,
    input  signed [ 2:0] iDelay_8,
    input  signed [ 2:0] iDelay_9,

    output signed [15:0] oMul_0,
    output signed [15:0] oMul_1,
    output signed [15:0] oMul_2,
    output signed [15:0] oMul_3,
    output signed [15:0] oMul_4,
    output signed [15:0] oMul_5,
    output signed [15:0] oMul_6,
    output signed [15:0] oMul_7,
    output signed [15:0] oMul_8,
    output signed [15:0] oMul_9
);
    reg           [15:0] rMul_0;
    reg           [15:0] rMul_1;
    reg           [15:0] rMul_2;
    reg           [15:0] rMul_3;
    reg           [15:0] rMul_4;
    reg           [15:0] rMul_5;
    reg           [15:0] rMul_6;
    reg           [15:0] rMul_7;
    reg           [15:0] rMul_8;
    reg           [15:0] rMul_9;

    reg           [ 3:0] cnt;

    always @(posedge iClk12M)
    begin
        if(!iRsn)
        begin
            rMul_0 <= 16'd0;
            rMul_1 <= 16'd0;
            rMul_2 <= 16'd0;
            rMul_3 <= 16'd0;
            rMul_4 <= 16'd0;
            rMul_5 <= 16'd0;
            rMul_6 <= 16'd0;
            rMul_7 <= 16'd0;
            rMul_8 <= 16'd0;
            rMul_9 <= 16'd0;

            cnt    <=  4'd0;
        end

        else if(iEnMul)
        begin
            case(cnt)
            4'd0 : rMul_0 <= iCoeff * iDelay_0;
            4'd1 : rMul_1 <= iCoeff * iDelay_1;
            4'd2 : rMul_2 <= iCoeff * iDelay_2;
            4'd3 : rMul_3 <= iCoeff * iDelay_3;
            4'd4 : rMul_4 <= iCoeff * iDelay_4;
            4'd5 : rMul_5 <= iCoeff * iDelay_5;
            4'd6 : rMul_6 <= iCoeff * iDelay_6;
            4'd7 : rMul_7 <= iCoeff * iDelay_7;
            4'd8 : rMul_8 <= iCoeff * iDelay_8;
            4'd9 : rMul_9 <= iCoeff * iDelay_9;
            endcase

            if(cnt < 4'd9)
                cnt <= cnt + 4'd1;

            else
                cnt <= 4'd0;

        end

    end

    assign oMul_0 = rMul_0;
    assign oMul_1 = rMul_1;
    assign oMul_2 = rMul_2;
    assign oMul_3 = rMul_3;
    assign oMul_4 = rMul_4;
    assign oMul_5 = rMul_5;
    assign oMul_6 = rMul_6;
    assign oMul_7 = rMul_7;
    assign oMul_8 = rMul_8;
    assign oMul_9 = rMul_9;

endmodule
