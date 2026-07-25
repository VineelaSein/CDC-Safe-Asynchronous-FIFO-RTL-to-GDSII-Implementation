create_clock -name wclk -period 10 [get_ports wclk]
create_clock -name rclk -period 7  [get_ports rclk]
set_clock_groups -asynchronous -group {wclk} -group {rclk}

set_input_delay 2 -clock wclk [get_ports {wrstn wr_en wr_data[*]}]
set_output_delay 2 -clock wclk [get_ports {wfull}]

set_input_delay 2 -clock rclk [get_ports {rrstn rd_en}]
set_output_delay 2 -clock rclk [get_ports {rd_data[*] rempty}]
