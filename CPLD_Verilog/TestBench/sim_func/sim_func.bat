ECHO OFF
del vsim.wlf/Q
del transcript/Q
del wlft*/Q
RMDIR work /S /Q

ECHO ON

rem SET MODELSIM=C:\questasim64_10.7c\modelsim.ini
rem call modelsim -do CPLD_CONTROL_tb_func.do
call "questasim.exe" -do CPLD_CONTROL_tb_func.do
