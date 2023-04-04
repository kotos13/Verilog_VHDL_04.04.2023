---------------------------------------------------------------------------------------------------------
-- Temperature sensor MAX6630MUT-T simulation model
---------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Temp_sensor_model is
	generic
	(
		C_TEMP_SENSOR_PO_WL					: natural := 16;
		C_TEMP_SENSOR_DATA_WL				: natural := 13
	);
	port
	(
		Temp_sensor_Data_IN					: in std_logic_vector ((C_TEMP_SENSOR_DATA_WL-1) downto 0) := (others => '0');		-- ������� ����, �� ������� ������� ���������� ������� ��� �����������

		Temp_sensor_SCK_IN					: in std_logic := '0';			-- serial clock input
		Temp_sensor_CS_IN					: in std_logic := '1';			-- chip-select input
		Temp_sensor_SO_OUT					: out std_logic					-- serial data output
	);
end Temp_sensor_model;
---------------------------------------------------------------------------------------------------------
--*****************************************************************************************************--
---------------------------------------------------------------------------------------------------------
architecture Behavioral_Temp_sensor_model of Temp_sensor_model is
---------------------------------------------------------------------------------------------------------
-- Component declaration

---------------------------------------------------------------------------------------------------------
-- Signal declaration
signal	Temp_sensor_PO_Buf_signal			: std_logic_vector ((C_TEMP_SENSOR_PO_WL-1) downto 0) := (1 downto 0 => 'X', others => '0');
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------------------------------------
Temp_sensor_PO_Buf_signal(2) <= '0';
Temp_sensor_PO_Buf_signal(1 downto 0) <= "XX";
---------------------------------------------------------------------------------------------------------
process
variable Data_serial_counter : natural range C_TEMP_SENSOR_PO_WL downto 0;
begin
	wait until Temp_sensor_CS_IN = '0';
	Temp_sensor_PO_Buf_signal((C_TEMP_SENSOR_PO_WL-1) downto (C_TEMP_SENSOR_PO_WL-C_TEMP_SENSOR_DATA_WL)) <= Temp_sensor_Data_IN;
	Data_serial_counter := C_TEMP_SENSOR_PO_WL-1;
	wait for 80 ns;
	Temp_sensor_SO_OUT <= Temp_sensor_PO_Buf_signal(Data_serial_counter);
	while (Temp_sensor_CS_IN = '0') loop
		wait until falling_edge(Temp_sensor_SCK_IN);
		wait for 80 ns;
		Temp_sensor_SO_OUT <= Temp_sensor_PO_Buf_signal(Data_serial_counter-1);
		Data_serial_counter := Data_serial_counter - 1;
		if (Data_serial_counter = 0) then
			Data_serial_counter := C_TEMP_SENSOR_PO_WL;
		end if;
	end loop;
end process;
---------------------------------------------------------------------------------------------------------
end Behavioral_Temp_sensor_model;