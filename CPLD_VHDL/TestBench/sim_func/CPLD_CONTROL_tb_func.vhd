library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity CPLD_CONTROL_tb_func is
	generic
	(
		C_SIMULATION_TB						: boolean := true;		-- �������� � ���������� ��� ModelSim
		C_LEDS_QUANTITY_TB					: natural := 24;
		C_CRASH_TYPE_TB						: natural := 1;			-- '0' - power crash, '1' - temperature crash, '2' - power & temperature crash

		C_TEMP_SENSOR_PO_WL_TB				: natural := 16;
		C_TEMP_SENSOR_DATA_WL_TB			: natural := 13;
		C_MAX_TEMP_TB						: real := 40.0			-- ����� �����������, ���� ������� (�������� �� -55 �� +150)
	);
end CPLD_CONTROL_tb_func;

---------------------------------------------------------------------------------------------------------
--*****************************************************************************************************--
---------------------------------------------------------------------------------------------------------
architecture behavior of CPLD_CONTROL_tb_func is
---------------------------------------------------------------------------------------------------------
-- Component declaration
component CPLD_CONTROL
	generic
	(
		C_SIMULATION						: boolean := false;
		C_LEDS_QUANTITY						: natural := 24;

		C_TEMP_SENSOR_PO_WL					: natural := 16;
		C_TEMPERATURE_DATA_WL				: natural := 13;
		C_MAX_TEMP							: real := 40.0			-- ����� �����������, ���� ������� (�������� �� -55 �� +150)
	);
	port
	(
		-- Clock input
		CLK_IN								: in std_logic;

		-- Power control inputs
--		PGOOD_All_bus_IN					: in std_logic_vector ((C_LEDS_QUANTITY_TB+1-1) downto 0);-- '1' - ok, '0' - fail
		PGOOD_All_bus_IN					: in std_logic_vector ((C_LEDS_QUANTITY+1-1) downto 0);	-- '1' - ok, '0' - fail

		-- User switch inputs
		KEY_CPLD_IN							: in std_logic_vector (3 downto 0);						-- '1' - unpressed, '0' - pressed

		-- LEDs control intputs
--		LED_DRIVER_SDO_IN					: in std_logic;				-- led driver output data line (serial)

		-- Temperature sensor data input
		Temp_sensor_SO_IN					: in std_logic;				-- temperature sensor output data line (serial)

		-- Power enable outputs
		EN_ANALOG_PWR_OUT					: out std_logic;			-- '0' - off, '1' - on
		EN_DIGITAL_3V3_OUT					: out std_logic;			-- '0' - off, '1' - on
		EN_5V0_POWER_OUT					: out std_logic;			-- '0' - off, '1' - on
		EN_VCC_2V5_OUT						: out std_logic;			-- '0' - off, '1' - on
		EN_VCC_1V0_INT_OUT					: out std_logic;			-- '0' - off, '1' - on

		-- Front LEDs outputs
		LED_CPLD_0_RED_OUT,
		LED_CPLD_1_GREEN_OUT,
		LED_CPLD_2_RED_OUT,
		LED_CPLD_3_GREEN_OUT				: out std_logic;			-- '1' - off, '0' - on

		-- LEDs control outputs
		LED_DRIVER_CLK_OUT					: out std_logic;			-- led driver clock
		LED_DRIVER_SDI_OUT					: out std_logic := '0';		-- led driver input data line (serial)
		LED_DRIVER_LE_OUT					: out std_logic;			-- led driver latch enable

		-- Temperature sensor control outputs
		Temp_sensor_CS_OUT					: out std_logic;			-- temperature sensor chip select
		Temp_sensor_SCK_OUT					: out std_logic;			-- temperature sensor clock

		-- PROG B output
		FPGA_PROG_B_OUT						: out std_logic				-- '0' - reset FPGA
	);
end component;
---------------------------------------------------------------------------------------------------------
component LED_driver
	generic
	(
		C_N									: natural := 16		-- �����������
	);
	port
	(
		LED_Clk, LED_LE, LED_SDI			: in std_logic := '0';
		LED_OE								: in std_logic := '1';
		LED_SDO								: out std_logic;
		LED_PO								: out std_logic_vector (C_N-1 downto 0)
	);
end component;
---------------------------------------------------------------------------------------------------------
component Temp_sensor_model
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
end component;
---------------------------------------------------------------------------------------------------------
-- Type declaration

---------------------------------------------------------------------------------------------------------
-- Constant declaration
constant	CLK_PERIOD_TB_const				: time := 25 ns;		-- 40 MHz
---------------------------------------------------------------------------------------------------------
-- Signal declaration
signal	CLK_TB_signal						: std_logic := '0';
signal	Test_PGOOD_All_bus_TB_signal		: std_logic_vector (C_LEDS_QUANTITY_TB+1-1 downto 0) := (others => '0');
signal	Test_KEY_CPLD_TB_signal				: std_logic_vector (3 downto 0) := (others => '1');

signal	EN_Power_TB_signal					: std_logic;

signal	LED_Clk_TB_signal					: std_logic;
signal	LED_LE_TB_signal					: std_logic;
signal	LED_SDI_TB_signal					: std_logic;
--signal	LED_SDO_TB_signal				: std_logic;

signal	Temp_sensor_SO_TB_signal			: std_logic;
signal	Temp_sensor_CS_TB_signal			: std_logic;
signal	Temp_sensor_SCK_TB_signal			: std_logic;
signal	Temp_sensor_Data_TB_signal			: std_logic_vector ((C_TEMP_SENSOR_DATA_WL_TB-1) downto 0) := ((C_TEMP_SENSOR_DATA_WL_TB-1) => '1', others => '0');
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------------------------------------
-- Simulation procedures
CPLD_CONTROL_inst: CPLD_CONTROL
	generic map
	(
		C_SIMULATION						=> C_SIMULATION_TB,
		C_LEDS_QUANTITY						=> C_LEDS_QUANTITY_TB,

		C_TEMP_SENSOR_PO_WL					=> C_TEMP_SENSOR_PO_WL_TB,
		C_TEMPERATURE_DATA_WL				=> C_TEMP_SENSOR_DATA_WL_TB,
		C_MAX_TEMP							=> C_MAX_TEMP_TB
	)
	port map
	(
		-- Clock input
		CLK_IN								=> CLK_TB_signal,

		-- Power control inputs
		PGOOD_All_bus_IN					=> Test_PGOOD_All_bus_TB_signal,

		-- User switch inputs
		KEY_CPLD_IN							=> Test_KEY_CPLD_TB_signal,

		-- LEDs control intputs
--		LED_DRIVER_SDO_IN					=> LED_SDO_TB_signal,

		-- Temperature sensor data input
		Temp_sensor_SO_IN					=> Temp_sensor_SO_TB_signal,

		-- Power enable outputs
		EN_ANALOG_PWR_OUT					=> EN_Power_TB_signal,
		EN_DIGITAL_3V3_OUT					=> open,
		EN_5V0_POWER_OUT					=> open,
		EN_VCC_2V5_OUT						=> open,
		EN_VCC_1V0_INT_OUT					=> open,

		-- Front LEDs outputs
		LED_CPLD_0_RED_OUT					=> open,
		LED_CPLD_1_GREEN_OUT				=> open,
		LED_CPLD_2_RED_OUT					=> open,
		LED_CPLD_3_GREEN_OUT				=> open,

		-- LEDs control outputs
		LED_DRIVER_CLK_OUT					=> LED_Clk_TB_signal,
		LED_DRIVER_SDI_OUT					=> LED_SDI_TB_signal,
		LED_DRIVER_LE_OUT					=> LED_LE_TB_signal,

		-- Temperature sensor control outputs
		Temp_sensor_CS_OUT					=> Temp_sensor_CS_TB_signal,
		Temp_sensor_SCK_OUT					=> Temp_sensor_SCK_TB_signal,

		-- PROG B output
		FPGA_PROG_B_OUT						=> open
	);
---------------------------------------------------------------------------------------------------------
RTL_LED_driver: LED_driver
	generic map
	(
		C_N									=> C_LEDS_QUANTITY_TB
	)
	port map
	(
		LED_Clk								=> LED_Clk_TB_signal,
		LED_LE								=> LED_LE_TB_signal,
		LED_OE								=> '0',
		LED_SDI								=> LED_SDI_TB_signal,
		LED_SDO								=> open,
		LED_PO								=> open
	);
---------------------------------------------------------------------------------------------------------
Behavioral_Temp_sensor_model: Temp_sensor_model
	generic map
	(
		C_TEMP_SENSOR_PO_WL					=> C_TEMP_SENSOR_PO_WL_TB,
		C_TEMP_SENSOR_DATA_WL				=> C_TEMP_SENSOR_DATA_WL_TB
	)
	port map
	(
		Temp_sensor_Data_IN					=> Temp_sensor_Data_TB_signal,

		Temp_sensor_SCK_IN					=> Temp_sensor_SCK_TB_signal,
		Temp_sensor_CS_IN					=> Temp_sensor_CS_TB_signal,
		Temp_sensor_SO_OUT					=> Temp_sensor_SO_TB_signal
	);
---------------------------------------------------------------------------------------------------------
-- Clock
CLK_TB_signal <= not CLK_TB_signal after CLK_PERIOD_TB_const/2;
---------------------------------------------------------------------------------------------------------
GEN_POWER_CRASH: if (C_CRASH_TYPE_TB = 0 or C_CRASH_TYPE_TB = 2) generate		-- Power crash or Power & Temperature crash
-- Test_PGOOD_All_bus_TB_signal
TEST_POWER_GOOD: process -- '1' - ok, '0' - fail
begin
	Test_PGOOD_All_bus_TB_signal <= B"0_0000_0000_0000_0000_0000_0000";
	wait for 2.8 us;
	Test_PGOOD_All_bus_TB_signal <= B"1_1111_1111_1111_1111_1111_1111";
--	wait for 1700 ms;
	wait for 7.2 us;
	Test_PGOOD_All_bus_TB_signal <= B"0_1011_1111_1111_1111_1111_1110";
	wait on EN_Power_TB_signal;
	wait for 50 ns;
	Test_PGOOD_All_bus_TB_signal <= B"0_0000_0000_0000_0000_0000_0000";
	wait;
end process;

-- Temp_sensor_Data_TB_signal
TEST_TEMP_GOOD: process
begin
	wait for 5 us;
	if (C_CRASH_TYPE_TB = 0) then
		Temp_sensor_Data_TB_signal <= conv_std_logic_vector(integer( (C_MAX_TEMP_TB-1.0) / 0.0625), C_TEMP_SENSOR_DATA_WL_TB);
	else
		Temp_sensor_Data_TB_signal <= conv_std_logic_vector(integer( (C_MAX_TEMP_TB+1.0) / 0.0625), C_TEMP_SENSOR_DATA_WL_TB);
	end if;
	wait;
end process;
end generate GEN_POWER_CRASH;


GEN_TEMP_CRASH: if (C_CRASH_TYPE_TB = 1) generate				-- Temp crash
-- Test_PGOOD_All_bus_TB_signal
TEST_POWER_GOOD: process -- '1' - ok, '0' - fail
begin
	Test_PGOOD_All_bus_TB_signal <= B"0_0000_0000_0000_0000_0000_0000";
	wait for 2.8 us;
	Test_PGOOD_All_bus_TB_signal <= B"1_1111_1111_1111_1111_1111_1111";
	wait on EN_Power_TB_signal;
	wait for 50 ns;
	Test_PGOOD_All_bus_TB_signal <= B"0_0000_0000_0000_0000_0000_0000";
	wait;
end process;

-- Temp_sensor_Data_TB_signal
TEST_TEMP_GOOD: process
begin
	wait for 5 us;
	Temp_sensor_Data_TB_signal <= conv_std_logic_vector(integer( (C_MAX_TEMP_TB-1.0) / 0.0625), C_TEMP_SENSOR_DATA_WL_TB);
	wait for 25 us;
	Temp_sensor_Data_TB_signal <= conv_std_logic_vector(integer( (C_MAX_TEMP_TB+1.0) / 0.0625), C_TEMP_SENSOR_DATA_WL_TB);
	wait;
end process;
end generate GEN_TEMP_CRASH;
---------------------------------------------------------------------------------------------------------
LED_TEST: process
begin
	Test_KEY_CPLD_TB_signal <= B"1111"; -- turn off all LEDs
	wait for 4 us;
	Test_KEY_CPLD_TB_signal <= B"1110"; -- turn on LED_CPLD_0_RED_OUT
	wait for 1 us;
	Test_KEY_CPLD_TB_signal <= B"1100"; -- turn on LED_CPLD_0_RED_OUT & LED_CPLD_1_GREEN_OUT
	wait for 1 us;
	Test_KEY_CPLD_TB_signal <= B"1001"; -- turn on LED_CPLD_1_GREEN_OUT & LED_CPLD_2_RED_OUT
	wait for 1 us;
	Test_KEY_CPLD_TB_signal <= B"0011"; -- turn on LED_CPLD_2_RED_OUT & LED_CPLD_3_GREEN_OUT
	wait for 1 us;
	Test_KEY_CPLD_TB_signal <= B"0111"; -- turn on LED_CPLD_3_GREEN_OUT
	wait for 1 us;
	Test_KEY_CPLD_TB_signal <= B"1111"; -- turn off all leds
	wait;
end process;
---------------------------------------------------------------------------------------------------------
end behavior;