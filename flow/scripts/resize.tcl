source $::env(SCRIPTS_DIR)/load.tcl
load_design 3_3_place_gp.odb 2_floorplan.sdc "Starting resizer"

proc print_banner {header} {
  puts "\n=========================================================================="
  puts "$header"
  puts "--------------------------------------------------------------------------"
}

estimate_parasitics -placement

source $::env(SCRIPTS_DIR)/report_metrics.tcl
report_metrics "resizer pre" false

print_banner "instance_count"
puts [sta::network_leaf_instance_count]

print_banner "pin_count"
puts [sta::network_leaf_pin_count]

puts ""

set_dont_use $::env(DONT_USE_CELLS)

# Do not buffer chip-level designs
if {![info exists ::env(FOOTPRINT)]} {
  puts "Perform port buffering..."
  buffer_ports
}

puts "Perform buffer insertion..."
repair_design

if { [info exists env(TIE_SEPARATION)] } {
  set tie_separation $env(TIE_SEPARATION)
} else {
  set tie_separation 0
}

# Repair tie lo fanout
puts "Repair tie lo fanout..."
set tielo_cell_name [lindex $env(TIELO_CELL_AND_PORT) 0]
set tielo_lib_name [get_name [get_property [lindex [get_lib_cell $tielo_cell_name] 0] library]]
set tielo_pin $tielo_lib_name/$tielo_cell_name/[lindex $env(TIELO_CELL_AND_PORT) 1]
repair_tie_fanout -separation $tie_separation $tielo_pin

# Repair tie hi fanout
puts "Repair tie hi fanout..."
set tiehi_cell_name [lindex $env(TIEHI_CELL_AND_PORT) 0]
set tiehi_lib_name [get_name [get_property [lindex [get_lib_cell $tiehi_cell_name] 0] library]]
set tiehi_pin $tiehi_lib_name/$tiehi_cell_name/[lindex $env(TIEHI_CELL_AND_PORT) 1]
repair_tie_fanout -separation $tie_separation $tiehi_pin

# hold violations are not repaired until after CTS

# post report

print_banner "report_floating_nets"
report_floating_nets

source $::env(SCRIPTS_DIR)/report_metrics.tcl
report_metrics "resizer"

print_banner "instance_count"
puts [sta::network_leaf_instance_count]

print_banner "pin_count"
puts [sta::network_leaf_pin_count]

puts ""

if {![info exists save_checkpoint] || $save_checkpoint} {
  write_db $::env(RESULTS_DIR)/3_4_place_resized.odb
}
