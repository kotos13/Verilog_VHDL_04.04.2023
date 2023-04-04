----------------------------------------------------------------------------------
-- ��������:				������ �������� ���������� � ����������� ��� �����
-- �������� ������:			������� �������������� ���� ���������� �������� (�������� ������� ������������ �������) � ����������� ����� ������� ������ �����������.
--							� ���������� ������ ������ �������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ����� ��� ������
--							����������. � ������ ������ ����������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ���������� ����
--							�� ���� ������� ������, ��������������� ���� ������ (�� �������� ������������ ������� ��� ��-�� ���������� ����������� ���������� �����������),
--							� �����, � ������ ������ �� �������� ������������ �������, ����������� �������� �������� ���������� ����, �������������� ���������� ������
--							����������� �������.
--							�������� ������� ���������� ������ �������� ��������� � ��������� ~1,68 � ����� ��� ���������.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library unisim;
--use unisim.vcomponents.all;

entity CPLD_CONTROL is
	generic
	(
		C_SIMULATION						: boolean := false;
		C_LEDS_QUANTITY						: natural := 24;

		C_TEMP_SENSOR_PO_WL					: natural := 16;
		C_TEMPERATURE_DATA_WL				: natural := 13;
		C_MAX_TEMP							: real := 60.0				-- ����� �����������, ���� ������� (�������� �� -55 �� +150)
	);
	port
	(
		-- Clock input
		CLK_IN								: in std_logic;

		-- Power control inputs
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
end CPLD_CONTROL;
---------------------------------------------------------------------------------------------------------
--*****************************************************************************************************--
---------------------------------------------------------------------------------------------------------
architecture struct of CPLD_CONTROL is
---------------------------------------------------------------------------------------------------------
-- Component declaration

---------------------------------------------------------------------------------------------------------
-- Constant declaration
constant	MAX_TEMP_CODE_CONST				: std_logic_vector ((C_TEMPERATURE_DATA_WL-1) downto 0) := conv_std_logic_vector(integer(C_MAX_TEMP / 0.0625), C_TEMPERATURE_DATA_WL);	-- (85 deg Celsius/0.0625 deg Celsius = 1360 = B"0_0101_0101_0000")
constant	FILTER_LENGTH					: natural := 3;

--constant	ACLK_DELAY						: time := 10 ns;	-- ��������� � ���������������� �����, � �������� ������� �����������
---------------------------------------------------------------------------------------------------------
-- Variable declaration

---------------------------------------------------------------------------------------------------------
-- Type declaration
type	TX_RX_mode_value is (Stop_state, Start_state, Run_state, Finish_state);
type	Strobe_value is (Strobe_state1, Strobe_state2, Strobe_state3);
---------------------------------------------------------------------------------------------------------
-- Signal declaration
signal	TX_curr_mode						: TX_RX_mode_value := Start_state;
signal	RX_curr_mode						: TX_RX_mode_value := Stop_state;

signal	GSR_signal							: std_logic;
signal	CLK_signal							: std_logic;
signal	CLK_COUNTER_signal					: std_logic_vector (26 downto 0) := (others => '0');
signal	START_CONTROL_TIME_signal			: std_logic := '0';
signal	CLK_DIV_TX							: std_logic;
signal	CLK_DIV_RX							: std_logic;
signal	CLK_DIV_filter						: std_logic;

signal	PGOOD_All_bus_signal				: std_logic_vector ((C_LEDS_QUANTITY-1) downto 0);
signal	PGOOD_filtered_signal				: std_logic_vector ((FILTER_LENGTH-1) downto 0) := (others => '1');
signal	SDI_Data_signal						: std_logic_vector ((C_LEDS_QUANTITY-1) downto 0) := (others => '0');

signal	ENABLE_ALL_POWER_INV_signal			: std_logic := '0';
signal	ENABLE_ALL_POWER_signal				: std_logic;

signal	CRASH_POWER_TRIG_signal				: std_logic := '0';
signal	CRASH_TEMP_TRIG_signal				: std_logic := '0';
signal	CRASH_signal						: std_logic;

signal	LED_DRIVER_LE_signal				: std_logic := '0';
signal	TX_sinchro_signal					: std_logic := '0';

signal	Temp_sensor_CS_signal				: std_logic := '1';
signal	Temp_sensor_SCK_signal				: std_logic;
signal	Temp_sensor_PO_signal				: std_logic_vector ((C_TEMP_SENSOR_PO_WL-1) downto 0) := (others => '0');
signal	Temperature_data_signal				: std_logic_vector ((C_TEMPERATURE_DATA_WL-1) downto 0) := conv_std_logic_vector(-(2 ** (C_TEMPERATURE_DATA_WL-1)), C_TEMPERATURE_DATA_WL);
signal	RX_period_signal					: std_logic;
signal	RX_period_strobe_signal				: std_logic;
signal	RX_sinchro_signal					: std_logic := '0';
signal	Strobe_curr_state					: Strobe_value := Strobe_state1;
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------------------------------------
-- Clock
--CLK_INst: BUFG port map (I => CLK_IN, O => CLK_signal);
CLK_signal <= CLK_IN;
---------------------------------------------------------------------------------------------------------
-- ROC
--roc_inst: ROC port map (O => GSR_signal);
process begin	-- ��������� � ���������������� �����, � �������� ������� ����������� (��������������� �������� �����������)
	GSR_signal <= '1';
	wait for 100 ns;
	GSR_signal <= '0';
	wait;
end process;

---------------------------------------------------------------------------------------------------------
-- Clock counter
process (GSR_signal, CLK_signal)
begin
	if (GSR_signal = '1') then
		CLK_COUNTER_signal <= (others => '0');
	elsif rising_edge(CLK_signal) then
		CLK_COUNTER_signal <= CLK_COUNTER_signal + 1;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
CLK_DIV_TX <= CLK_COUNTER_signal(1);
--CLK_DIV_TX <= CLK_signal;
---------------------------------------------------------------------------------------------------------
CLK_DIV_RX <= CLK_COUNTER_signal(3);
---------------------------------------------------------------------------------------------------------
CLK_DIV_filter <= CLK_COUNTER_signal(2);			-- period 0.2 us (��� f = 40 ��� delay = 1/(40e6)*2*2^2)
--CLK_DIV_filter <= CLK_signal;
---------------------------------------------------------------------------------------------------------
GEN_SIMULATION: if (C_SIMULATION) generate
process (GSR_signal, CLK_COUNTER_signal(7))
begin
	if (GSR_signal = '1') then
		START_CONTROL_TIME_signal <= '0';
	elsif rising_edge(CLK_COUNTER_signal(7)) then
		START_CONTROL_TIME_signal <= '1';			-- delay 3.2 us (��� f = 40 ��� delay = 1/(40e6)*2^7)
	end if;
end process;
RX_period_signal <= CLK_COUNTER_signal(8);			-- period 12.8 us (��� f = 40 ��� delay = 1/(40e6)*2*2^8)
end generate GEN_SIMULATION;


GEN_SIMULATION_NONE: if (not C_SIMULATION) generate
process (GSR_signal, CLK_COUNTER_signal(26))
begin
	if (GSR_signal = '1') then
		START_CONTROL_TIME_signal <= '0';
	elsif rising_edge(CLK_COUNTER_signal(26)) then
		START_CONTROL_TIME_signal <= '1';			-- delay 1.68 s (��� f = 40 ��� delay = 1/(40e6)*2^26)
	end if;
end process;
RX_period_signal <= CLK_COUNTER_signal(24);			-- period 0.84 s (��� f = 40 ��� delay = 1/(40e6)*2*2^24)
end generate GEN_SIMULATION_NONE;
---------------------------------------------------------------------------------------------------------
PGOOD_All_bus_signal((C_LEDS_QUANTITY-1) downto 17)	<= PGOOD_All_bus_IN((C_LEDS_QUANTITY-1) downto 17);
PGOOD_All_bus_signal(16)							<= PGOOD_All_bus_IN(16) and PGOOD_All_bus_IN(C_LEDS_QUANTITY);
PGOOD_All_bus_signal(15 downto 0)					<= PGOOD_All_bus_IN(15 downto 0);
---------------------------------------------------------------------------------------------------------
-- PGOOD_filtered shift register
process (GSR_signal, CLK_DIV_filter)
begin
	if (GSR_signal = '1') then
		PGOOD_filtered_signal(0) <= '1';
	elsif rising_edge(CLK_DIV_filter) then
		if (PGOOD_All_bus_signal /= not conv_std_logic_vector(0, C_LEDS_QUANTITY)) then
			PGOOD_filtered_signal(0) <= '0';
		else
			PGOOD_filtered_signal(0) <= '1';
		end if;
	end if;
end process;

PGOOD_SHIFT_REGISTER: for i in 1 to (FILTER_LENGTH-1) generate
process (GSR_signal, CLK_DIV_filter)
begin
	if (GSR_signal = '1') then
		PGOOD_filtered_signal(i) <= '1';
	elsif rising_edge(CLK_DIV_filter) then
		PGOOD_filtered_signal(i) <= PGOOD_filtered_signal(i-1);
	end if;
end process;
end generate PGOOD_SHIFT_REGISTER;
---------------------------------------------------------------------------------------------------------
process (GSR_signal, CLK_signal)
begin
	if (GSR_signal = '1') then
		CRASH_POWER_TRIG_signal <= '0';
	elsif rising_edge(CLK_signal) then
		if (PGOOD_filtered_signal = conv_std_logic_vector(0, FILTER_LENGTH) and START_CONTROL_TIME_signal = '1' and CRASH_TEMP_TRIG_signal = '0') then
			CRASH_POWER_TRIG_signal <= '1';							-- POWER CRASH
		end if;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
CRASH_signal <= CRASH_POWER_TRIG_signal or CRASH_TEMP_TRIG_signal;
---------------------------------------------------------------------------------------------------------
-- ������������ ������� ������ �� ������������
process (GSR_signal, CRASH_POWER_TRIG_signal)
begin
	if (GSR_signal = '1') then
		SDI_Data_signal <= (others => '0');
	elsif rising_edge(CRASH_POWER_TRIG_signal) then
		SDI_Data_signal <= not PGOOD_All_bus_signal;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
-- ���������� ���������� �������
process (GSR_signal, CLK_signal)
begin
	if (GSR_signal = '1') then
		ENABLE_ALL_POWER_INV_signal <= '0';
	elsif rising_edge(CLK_signal) then
		ENABLE_ALL_POWER_INV_signal <= CRASH_signal;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
ENABLE_ALL_POWER_signal <= not ENABLE_ALL_POWER_INV_signal;
---------------------------------------------------------------------------------------------------------
EN_ANALOG_PWR_OUT <= ENABLE_ALL_POWER_signal;
EN_DIGITAL_3V3_OUT <= ENABLE_ALL_POWER_signal;
EN_5V0_POWER_OUT <= ENABLE_ALL_POWER_signal;
EN_VCC_2V5_OUT <= ENABLE_ALL_POWER_signal;
EN_VCC_1V0_INT_OUT <= ENABLE_ALL_POWER_signal;
---------------------------------------------------------------------------------------------------------
FPGA_PROG_B_OUT <= not CRASH_signal;
---------------------------------------------------------------------------------------------------------
LED_CPLD_0_RED_OUT <= KEY_CPLD_IN(0) and not CRASH_POWER_TRIG_signal;
LED_CPLD_1_GREEN_OUT <= KEY_CPLD_IN(1) and CRASH_POWER_TRIG_signal;
LED_CPLD_2_RED_OUT <= KEY_CPLD_IN(2) and not CRASH_TEMP_TRIG_signal;
LED_CPLD_3_GREEN_OUT <= KEY_CPLD_IN(3) and CRASH_TEMP_TRIG_signal;
---------------------------------------------------------------------------------------------------------
-- ���������� -------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
-- ������ �����������. ����� ������ �� ����� LED_DRIVER_SDI_OUT
process (GSR_signal, CLK_DIV_TX)
variable Data_serial_counter_TX : natural range C_LEDS_QUANTITY downto 0;
begin
	if (GSR_signal = '1') then
		LED_DRIVER_SDI_OUT <= '0';
		LED_DRIVER_LE_signal <= '0';
		TX_sinchro_signal <= '0';
		Data_serial_counter_TX := C_LEDS_QUANTITY;
	elsif falling_edge(CLK_DIV_TX) then									-- ������������� �� ������� ������ CLK_DIV_TX
		if (TX_curr_mode = Run_state) then
			if (Data_serial_counter_TX /= 0) then
				LED_DRIVER_SDI_OUT <= SDI_Data_signal(Data_serial_counter_TX-1);
				TX_sinchro_signal <= '1';
				Data_serial_counter_TX := Data_serial_counter_TX - 1;
			else
				LED_DRIVER_SDI_OUT <= '0';
				LED_DRIVER_LE_signal <= '1';
				TX_sinchro_signal <= '0';
				Data_serial_counter_TX := C_LEDS_QUANTITY;
			end if;
		elsif (TX_curr_mode = Finish_state) then
			LED_DRIVER_LE_signal <= '0';
		end if;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
LED_DRIVER_CLK_OUT <= CLK_DIV_TX and TX_sinchro_signal;
---------------------------------------------------------------------------------------------------------
LED_DRIVER_LE_OUT <= LED_DRIVER_LE_signal;
---------------------------------------------------------------------------------------------------------
-- �������� ������� ���������� ������������
process (GSR_signal, CLK_DIV_TX)
begin
	if (GSR_signal = '1') then
		TX_curr_mode <= Start_state;
	elsif rising_edge(CLK_DIV_TX) then

		case TX_curr_mode is
----------
			when Stop_state =>
				if (CRASH_POWER_TRIG_signal = '0') then
					TX_curr_mode <= Stop_state;
				else
					TX_curr_mode <= Start_state;
				end if;
----------
			when Start_state =>
				TX_curr_mode <= Run_state;
----------
			when Run_state =>
				if (LED_DRIVER_LE_signal = '1') then
					TX_curr_mode <= Finish_state;
				else
					TX_curr_mode <= Run_state;
				end if;
----------
			when Finish_state =>
				if (CRASH_POWER_TRIG_signal = '1') then
					TX_curr_mode <= Finish_state;
				else
					TX_curr_mode <= Stop_state;
				end if;
----------
			when others =>
				TX_curr_mode <= Stop_state;
		end case;

	end if;
end process;
---------------------------------------------------------------------------------------------------------
-- ������� ������� ����������� -------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
process (GSR_signal, CLK_signal)
begin
	if (GSR_signal = '1') then
		CRASH_TEMP_TRIG_signal <= '0';
	elsif rising_edge(CLK_signal) then
		if (signed(Temperature_data_signal) >= signed(MAX_TEMP_CODE_CONST) and CRASH_POWER_TRIG_signal = '0') then
			CRASH_TEMP_TRIG_signal <= '1';							-- TEMP CRASH
		end if;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
-- ������ ��������. ���� ������ �� ���� Temp_sensor_SO_IN
process (GSR_signal, CLK_DIV_RX)
variable Data_serial_counter_RX : natural range 0 to C_TEMP_SENSOR_PO_WL;
begin
	if (GSR_signal = '1') then
		Temp_sensor_CS_signal <= '1';
		RX_sinchro_signal <= '0';
		Data_serial_counter_RX := 0;
		Temperature_data_signal <= conv_std_logic_vector(-(2 ** (C_TEMPERATURE_DATA_WL-1)), C_TEMPERATURE_DATA_WL);
	elsif falling_edge(CLK_DIV_RX) then									-- ������������� �� ������� ������ CLK_DIV_RX
		if (RX_curr_mode = Run_state) then
			if (Data_serial_counter_RX /= C_TEMP_SENSOR_PO_WL) then
				Temp_sensor_CS_signal <= '0';
				RX_sinchro_signal <= '1';
				Data_serial_counter_RX := Data_serial_counter_RX + 1;
			else
				Temp_sensor_CS_signal <= '1';
				RX_sinchro_signal <= '0';
				Data_serial_counter_RX := 0;
				Temperature_data_signal <= Temp_sensor_PO_signal((C_TEMP_SENSOR_PO_WL-1) downto (C_TEMP_SENSOR_PO_WL-C_TEMPERATURE_DATA_WL));
			end if;
		end if;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
Temp_sensor_SCK_signal <= CLK_DIV_RX and RX_sinchro_signal;
---------------------------------------------------------------------------------------------------------
Temp_sensor_SCK_OUT <= Temp_sensor_SCK_signal;
---------------------------------------------------------------------------------------------------------
Temp_sensor_CS_OUT <= Temp_sensor_CS_signal;
---------------------------------------------------------------------------------------------------------
-- Temp_sensor_PO shift register
process (GSR_signal, Temp_sensor_SCK_signal)
begin
	if (GSR_signal = '1') then
		Temp_sensor_PO_signal(0) <= '0';
	elsif rising_edge(Temp_sensor_SCK_signal) then
		Temp_sensor_PO_signal(0) <= Temp_sensor_SO_IN;
	end if;
end process;

Temp_sensor_PO_SHIFT_REGISTER: for i in 1 to (C_TEMP_SENSOR_PO_WL-1) generate
process (GSR_signal, Temp_sensor_SCK_signal)
begin
	if (GSR_signal = '1') then
		Temp_sensor_PO_signal(i) <= '0';
	elsif rising_edge(Temp_sensor_SCK_signal) then
		Temp_sensor_PO_signal(i) <= Temp_sensor_PO_signal(i-1);
	end if;
end process;
end generate Temp_sensor_PO_SHIFT_REGISTER;
---------------------------------------------------------------------------------------------------------
-- �������� ������� ���������� ������� ������� ���������� ������ � ������� �����������
process (GSR_signal, CLK_signal)
begin
	if (GSR_signal = '1') then
		Strobe_curr_state <= Strobe_state1;
	elsif rising_edge(CLK_signal) then

		case Strobe_curr_state is
----------
			when Strobe_state1 =>
				if (RX_period_signal = '1' and CRASH_signal = '0' and START_CONTROL_TIME_signal = '1') then
					Strobe_curr_state <= Strobe_state2;
				else
					Strobe_curr_state <= Strobe_state1;
				end if;
----------
			when Strobe_state2 =>
				if (RX_curr_mode = Start_state) then
					Strobe_curr_state <= Strobe_state3;
				else
					Strobe_curr_state <= Strobe_state2;
				end if;
----------
			when Strobe_state3 =>
				if (RX_period_signal = '1') then
					Strobe_curr_state <= Strobe_state3;
				else
					Strobe_curr_state <= Strobe_state1;
				end if;
----------
			when others =>
				Strobe_curr_state <= Strobe_state1;
		end case;

	end if;
end process;
---------------------------------------------------------------------------------------------------------
RX_period_strobe_signal <= '1' when (Strobe_curr_state = Strobe_state2) else '0';
---------------------------------------------------------------------------------------------------------
-- �������� ������� ���������� ���������
process (GSR_signal, CLK_DIV_RX)
begin
	if (GSR_signal = '1') then
		RX_curr_mode <= Stop_state;
	elsif rising_edge(CLK_DIV_RX) then

		case RX_curr_mode is
----------
			when Stop_state =>
				if (RX_period_strobe_signal = '1') then
					RX_curr_mode <= Start_state;
				else
					RX_curr_mode <= Stop_state;
				end if;
----------
			when Start_state =>
				RX_curr_mode <= Run_state;
----------
			when Run_state =>
				if (Temp_sensor_CS_signal = '0') then
					RX_curr_mode <= Run_state;
				else
					RX_curr_mode <= Finish_state;
				end if;
----------
			when Finish_state =>
				RX_curr_mode <= Stop_state;
----------
			when others =>
				RX_curr_mode <= Stop_state;
		end case;

	end if;
end process;
---------------------------------------------------------------------------------------------------------
end struct;