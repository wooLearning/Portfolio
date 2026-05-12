  // Interface-level assertions:
  // These check signal quality and simple bus timing rules.

  property p_no_unknown_ctrl_when_selected;
    @(posedge iClk) disable iff (!iRstn)
      iCs |-> (!$isunknown(iWea) && !$isunknown(iAddr));
  endproperty

  property p_no_unknown_write_data_on_write;
    @(posedge iClk) disable iff (!iRstn)
      (iCs && iWea) |-> !$isunknown(iWData);
  endproperty

  property p_ctrl_low_during_reset;
    @(posedge iClk)
      !iRstn |-> (!iCs && !iWea);
  endproperty

  property p_addr_stable_while_selected;
    @(posedge iClk) disable iff (!iRstn)
      (iCs && $past(iCs)) |-> $stable(iAddr);
  endproperty

  a_no_unknown_ctrl_when_selected : assert property (p_no_unknown_ctrl_when_selected)
    else $error("RAM_IF_SVA: iWea or iAddr has X/Z while iCs is high");

  a_no_unknown_write_data_on_write : assert property (p_no_unknown_write_data_on_write)
    else $error("RAM_IF_SVA: iWData has X/Z during write transaction");

  a_ctrl_low_during_reset : assert property (p_ctrl_low_during_reset)
    else $error("RAM_IF_SVA: iCs/iWea should stay low during reset");

  a_addr_stable_while_selected : assert property (p_addr_stable_while_selected)
    else $error("RAM_IF_SVA: iAddr changed during an active transaction");
