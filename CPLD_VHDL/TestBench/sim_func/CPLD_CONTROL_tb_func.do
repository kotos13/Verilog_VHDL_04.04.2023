set PrefSource(font) {{Courier New Cyr} 9 normal}

vlib work

vcom -2008 -work work ../../hdl/vhdl/LED_driver.vhd
vcom -2008 -work work ../../hdl/vhdl/Temp_sensor_model.vhd
vcom -2008 -work work ../../hdl/vhdl/CPLD_CONTROL.vhd
vcom -2008 -work work CPLD_CONTROL_tb_func.vhd

#vsim -t 1ps -novopt -lib work CPLD_CONTROL_tb_func
vsim -t 1ps -voptargs=+acc -lib work CPLD_CONTROL_tb_func

do CPLD_CONTROL_wave_func.do

view wave
#add wave *
#view structure
#view signals

run 60 us
