# Run in Vivado Tcl, or: vivado -mode gui -source scripts/open_xsim_waves.tcl
# Read-only waveform inspection; no FPGA device or synthesis project required.
set project_root [file normalize [file join [file dirname [info script]] ..]]
set wave_file [file join $project_root results xsim bridge_tx4_rx8_seed20261009.wdb]
if {![file exists $wave_file]} {
  error "Run python scripts/run_xsim.py first: missing $wave_file"
}
open_wave_database $wave_file
create_wave_config apb_can_bridge
foreach signal {
  iPclk iPresetN iPsel iPenable iPwrite iPaddr iPwdata oPrdata oPready oPslverr
  oCanTxValid iCanTxReady oCanTxId oCanTxDlc oCanTxData iCanTxDone iCanTxError
  iCanRxValid iCanRxId oIrq dut/wTxCount dut/wRxCount dut/u_tx_ctrl/rCurState
} {
  add_wave /tb_apb_can_bridge/$signal
}
save_wave_config [file join $project_root results xsim apb_can_bridge.wcfg]
puts "WAVE_VIEW_READY: APB / TX / RX / FSM signals loaded"
