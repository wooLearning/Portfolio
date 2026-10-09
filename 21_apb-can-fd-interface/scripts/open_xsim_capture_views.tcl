# Open the two focused views used in the design report.
# Run from a fresh Vivado Tcl Console after run_xsim.py --smoke.
set project_root [file normalize [file join [file dirname [info script]] ..]]
set wave_file [file join $project_root results xsim bridge_tx4_rx8_seed20261009.wdb]
if {![file exists $wave_file]} {
  error "Run python scripts/run_xsim.py --smoke first: missing $wave_file"
}
open_wave_database $wave_file
open_wave_config [file join $project_root docs wavecfg tx_handshake.wcfg]
open_wave_config [file join $project_root docs wavecfg rx_full_exchange.wcfg]
puts "CAPTURE_VIEWS_READY: TX accept/done and RX full exchange"
