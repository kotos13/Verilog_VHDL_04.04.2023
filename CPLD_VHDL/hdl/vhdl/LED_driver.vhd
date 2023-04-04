---------------------------------------------------------------------------------------------------------
-- LED driver STM STP16D05 simulation model
---------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity LED_driver is
	generic
	(
		C_N									: natural := 16		-- разрядность
	);
	port
	(
		LED_Clk, LED_LE, LED_SDI			: in std_logic := '0';
		LED_OE								: in std_logic := '1';
		LED_SDO								: out std_logic;
		LED_PO								: out std_logic_vector (C_N-1 downto 0)
	);
end LED_driver;
---------------------------------------------------------------------------------------------------------
--*****************************************************************************************************--
---------------------------------------------------------------------------------------------------------
architecture RTL_LED_driver of LED_driver is
---------------------------------------------------------------------------------------------------------
-- Component declaration

---------------------------------------------------------------------------------------------------------
-- Signal declaration
signal	PO_signal							: std_logic_vector (C_N-1 downto 0) := (others => '0');
signal	RST_signal							: std_logic := '0';
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------------------------------------
-- Shift register
process (RST_signal, LED_Clk)
begin
	if (RST_signal = '1') then
		PO_signal(0) <= '0';
	elsif rising_edge(LED_Clk) then
		PO_signal(0) <= LED_SDI;
	end if;
end process;

SHIFT_REGISTER: for i in 1 to (C_N-1) generate
process (RST_signal, LED_Clk)
begin
	if (RST_signal = '1') then
		PO_signal(i) <= '0';
	elsif rising_edge(LED_Clk) then
		PO_signal(i) <= PO_signal(i-1);
	end if;
end process;
end generate SHIFT_REGISTER;
---------------------------------------------------------------------------------------------------------
process (LED_LE, LED_OE, PO_signal)
begin
	if (LED_OE = '1') then
		LED_PO <= (others => '0');
	elsif (LED_LE = '1') then
		LED_PO <= PO_signal;
	end if;
end process;
---------------------------------------------------------------------------------------------------------
LED_SDO <= PO_signal(C_N-1);
---------------------------------------------------------------------------------------------------------
end RTL_LED_driver;