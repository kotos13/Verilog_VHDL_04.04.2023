set PrefSource(font) {{Courier New Cyr} 9 normal}

vlib work

vlog ../../hdl/verilog/LED_driver.v
vlog ../../hdl/verilog/Temp_sensor_model.v
vlog ../../hdl/verilog/CPLD_CONTROL.v
vlog CPLD_CONTROL_tb_func.v

#vsim -t 1ps -L unisims_ver -novopt -lib work CPLD_CONTROL_tb_func
vsim -t 1ps -voptargs=+acc -lib work CPLD_CONTROL_tb_func

do CPLD_CONTROL_wave_func.do

view wave
#add wave *
#view structure
#view signals

run 60 us
