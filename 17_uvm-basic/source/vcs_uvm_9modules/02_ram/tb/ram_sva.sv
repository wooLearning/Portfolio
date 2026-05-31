`ifndef RAM_SVA_SV
`define RAM_SVA_SV

module ram_sva #(
  parameter int DATA_WIDTH = 32,
  parameter int DEPTH      = 16,
  parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
  input logic                  iClk,
  input logic                  iRstn,
  input logic                  iCs,
  input logic                  iWea,
  input logic [ADDR_WIDTH-1:0] iAddr,
  input logic [DATA_WIDTH-1:0] iWData,
  input logic [DATA_WIDTH-1:0] oRData
);

  property p_control_known_when_selected;
    @(posedge iClk) disable iff (!iRstn)
      iCs |-> (!$isunknown(iWea) && !$isunknown(iAddr));
  endproperty

  property p_idle_holds_read_data;
    @(posedge iClk) disable iff (!iRstn)
      !iCs |=> $stable(oRData);
  endproperty

  property p_write_then_next_read_same_addr;
    logic [ADDR_WIDTH-1:0] v_addr;
    logic [DATA_WIDTH-1:0] v_data;
    @(posedge iClk) disable iff (!iRstn)
      (iCs && iWea, v_addr = iAddr, v_data = iWData)
      ##1 (iCs && !iWea && iAddr == v_addr) |=> (oRData == v_data);
  endproperty

  a_control_known_when_selected : assert property (p_control_known_when_selected)
    else $error("RAM_SVA: control/address has X or Z while chip-select is high");

  a_idle_holds_read_data : assert property (p_idle_holds_read_data)
    else $error("RAM_SVA: oRData changed while iCs was low");

  a_write_then_next_read_same_addr : assert property (p_write_then_next_read_same_addr)
    else $error("RAM_SVA: next-cycle readback did not match previous write");

endmodule

`endif
