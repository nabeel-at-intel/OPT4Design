create_clock -name sys_clk -period 3 [get_ports clk]
create_clock -name v -period 3
set_output_delay -clock v -max 0 [get_ports data_output*]
set_input_delay -clock v -max 0 [get_ports data_input*]