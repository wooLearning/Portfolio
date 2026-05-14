`timescale 1ns / 1ps

/*
[MODULE_INFO_START]
Name: ApbPlicGateway
Role: Per-source PLIC gateway for level-style external interrupt requests
Summary:
  - Converts raw peripheral IRQ levels into one-cycle request pulses
  - Blocks a source after one request until the PLIC core reports completion
  - Reissues a request on completion when the raw level is still asserted
StateDescription:
  - GW_IDLE waits for a raw IRQ level and emits the first request pulse
  - GW_BLOCKED suppresses duplicate requests until completion/release
[MODULE_INFO_END]
*/
module ApbPlicGateway #(
  parameter integer P_NUM_SOURCES = 8
) (
  input  logic                       iClk,
  input  logic                       iRstn,
  input  logic [P_NUM_SOURCES-1:0]   iRawIrq,
  input  logic [P_NUM_SOURCES-1:0]   iCompletePulse,
  output logic [P_NUM_SOURCES-1:0]   oRequestPulse,
  output logic [P_NUM_SOURCES-1:0]   oBlocked
);

  typedef enum logic {
    GW_IDLE,
    GW_BLOCKED
  } gateway_state_e;

  gateway_state_e rState [0:P_NUM_SOURCES-1];
  gateway_state_e wStateNext [0:P_NUM_SOURCES-1];
  integer idxComb;
  integer idxSeq;
  genvar genSource;

  generate
    for (genSource = 0; genSource < P_NUM_SOURCES; genSource = genSource + 1) begin : g_blocked
      assign oBlocked[genSource] = (rState[genSource] == GW_BLOCKED);
    end
  endgenerate

  always_comb begin
    for (idxComb = 0; idxComb < P_NUM_SOURCES; idxComb = idxComb + 1) begin
      wStateNext[idxComb] = rState[idxComb];
      oRequestPulse[idxComb] = 1'b0;

      unique case (rState[idxComb])
        GW_IDLE: begin
          if (iRawIrq[idxComb]) begin
            oRequestPulse[idxComb] = 1'b1;
            wStateNext[idxComb] = GW_BLOCKED;
          end
        end

        GW_BLOCKED: begin
          if (iCompletePulse[idxComb]) begin
            if (iRawIrq[idxComb]) begin
              oRequestPulse[idxComb] = 1'b1;
              wStateNext[idxComb] = GW_BLOCKED;
            end
            else begin
              wStateNext[idxComb] = GW_IDLE;
            end
          end
        end

        default: begin
          wStateNext[idxComb] = GW_IDLE;
        end
      endcase
    end
  end

  always_ff @(posedge iClk or negedge iRstn) begin
    if (!iRstn) begin
      for (idxSeq = 0; idxSeq < P_NUM_SOURCES; idxSeq = idxSeq + 1) begin
        rState[idxSeq] <= GW_IDLE;
      end
    end
    else begin
      for (idxSeq = 0; idxSeq < P_NUM_SOURCES; idxSeq = idxSeq + 1) begin
        rState[idxSeq] <= wStateNext[idxSeq];
      end
    end
  end

endmodule
