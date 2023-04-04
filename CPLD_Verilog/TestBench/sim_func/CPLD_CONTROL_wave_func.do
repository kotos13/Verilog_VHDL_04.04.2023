onerror {resume}
quietly WaveActivateNextPane {} 0
#add wave -noupdate -divider Clock
add wave -noupdate -expand -group {System signals} -color Tan -itemcolor Tan /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/GSR_signal
add wave -noupdate -expand -group {System signals} -color Yellow -itemcolor Yellow /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/CLK_IN
add wave -noupdate -divider {PGOOD Bus}
add wave -noupdate -radix hexadecimal /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/PGOOD_All_bus_IN
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/PGOOD_All_bus_signal
add wave -noupdate -divider {Enable power}
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/START_CONTROL_TIME_signal
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/EN_ANALOG_PWR_OUT
add wave -noupdate -divider {FPGA Prog B}
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/FPGA_PROG_B_OUT
add wave -noupdate -divider LEDs
add wave -noupdate -color Red -itemcolor Red /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_CPLD_0_RED_OUT
add wave -noupdate -color Green -itemcolor Green /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_CPLD_1_GREEN_OUT
add wave -noupdate -color Red -itemcolor Red /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_CPLD_2_RED_OUT
add wave -noupdate -color Green -itemcolor Green /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_CPLD_3_GREEN_OUT
add wave -noupdate -divider {Key CPLD}
add wave -noupdate -radix hexadecimal /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/KEY_CPLD_IN
add wave -noupdate -divider {LED driver serial}
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_DRIVER_CLK_OUT
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_DRIVER_SDI_OUT
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/LED_DRIVER_LE_OUT
add wave -noupdate -divider {LED driver parallel data}
add wave -noupdate /CPLD_CONTROL_tb_func/RTL_LED_driver/LED_PO
add wave -noupdate -divider {Temp sensor serial}
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/Temp_sensor_CS_OUT
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/Temp_sensor_SCK_OUT
add wave -noupdate /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/Temp_sensor_SO_IN
add wave -noupdate -divider {Temp sensor data}
add wave -noupdate -radix decimal /CPLD_CONTROL_tb_func/Temp_sensor_Data_TB_signal
add wave -noupdate -radix decimal /CPLD_CONTROL_tb_func/CPLD_CONTROL_inst/Temperature_data_signal
add wave -noupdate -divider {Debug data}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 226
configure wave -valuecolwidth 66
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {1950377 ps}
