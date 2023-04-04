/*--------------------------------------------------------------------------------
��������:				������ �������� ���������� � ����������� ��� �����
�������� ������:		������� �������������� ���� ���������� �������� (�������� ������� ������������ �������) � ����������� ����� ������� ������ �����������.
						� ���������� ������ ������ �������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ����� ��� ������
						����������. � ������ ������ ����������� �������������� ��������� ������� � FPGA_PROG_B, � ������ ����������� LED_CPLD ���������� ����
						�� ���� ������� ������, ��������������� ���� ������ (�� �������� ������������ ������� ��� ��-�� ���������� ����������� ���������� �����������),
						� �����, � ������ ������ �� �������� ������������ �������, ����������� �������� �������� ���������� ����, �������������� ���������� ������
						����������� �������.
						�������� ������� ���������� ������ �������� ��������� � ��������� ~1,68 � ����� ��� ���������.
--------------------------------------------------------------------------------*/


`timescale 1 ns / 1 ps

module CPLD_CONTROL #(
	parameter C_SIMULATION = 0,
	parameter C_LEDS_QUANTITY = 24,
	parameter C_TEMP_SENSOR_PO_WL = 16,
	parameter C_TEMPERATURE_DATA_WL = 13,
	parameter C_MAX_TEMP = 60.0
)(
	input wire CLK_IN,
	input wire [(C_LEDS_QUANTITY+1-1):0]PGOOD_All_bus_IN,
	input wire [3:0]KEY_CPLD_IN,
		
	input wire Temp_sensor_SO_IN,
	output wire EN_ANALOG_PWR_OUT,
	output wire EN_DIGITAL_3V3_OUT,
	output wire EN_5V0_POWER_OUT,
	output wire EN_VCC_2V5_OUT,
	output wire EN_VCC_1V0_INT_OUT,

	output wire LED_CPLD_0_RED_OUT,
	output wire LED_CPLD_1_GREEN_OUT,
	output wire LED_CPLD_2_RED_OUT,
	output wire LED_CPLD_3_GREEN_OUT,

	output wire LED_DRIVER_CLK_OUT,
	output reg LED_DRIVER_SDI_OUT = 1'b0,
	output wire LED_DRIVER_LE_OUT,

	output wire Temp_sensor_CS_OUT,
	output wire Temp_sensor_SCK_OUT,
	output wire FPGA_PROG_B_OUT
);

parameter [C_TEMPERATURE_DATA_WL-1:0]MAX_TEMP_CODE_CONST = {{C_TEMPERATURE_DATA_WL{1'b0}} + (C_MAX_TEMP / 0.0625)};
parameter FILTER_LENGTH = 3;

parameter Stop_state = 2'b00;
parameter Start_state = 2'b01;
parameter Run_state = 2'b10;
parameter Finish_state = 2'b11;
parameter Strobe_state1 = 2'b00;
parameter Strobe_state2 = 2'b01;
parameter Strobe_state3 = 2'b10;

reg TX_curr_mode = Start_state;
reg RX_curr_mode = Stop_state;
reg GSR_signal;
reg CLK_signal;
reg [26:0]CLK_COUNTER_signal = 1'b0;
reg START_CONTROL_TIME_signal = 1'b0;
reg CLK_DIV_TX;
reg CLK_DIV_RX;
reg CLK_DIV_filter;

reg [(C_LEDS_QUANTITY-1):0]PGOOD_All_bus_signal;
reg [(FILTER_LENGTH-1):0]PGOOD_filtered_signal = {FILTER_LENGTH{1'b1}};
reg [(C_LEDS_QUANTITY-1):0]SDI_Data_signal = {C_LEDS_QUANTITY{1'b0}};

reg ENABLE_ALL_POWER_INV_signal = 1'b0;
reg ENABLE_ALL_POWER_signal;

reg CRASH_POWER_TRIG_signal = 1'b0;
reg CRASH_TEMP_TRIG_signal = 1'b0;
reg CRASH_signal;

reg LED_DRIVER_LE_signal = 1'b0;
reg TX_sinchro_signal = 1'b0;

reg Temp_sensor_CS_signal = 1'b1;
reg Temp_sensor_SCK_signal;
reg [(C_TEMP_SENSOR_PO_WL-1):0]Temp_sensor_PO_signal = {C_TEMP_SENSOR_PO_WL{1'b0}};
reg [C_TEMPERATURE_DATA_WL-1:0]Temperature_data_signal = {{C_TEMPERATURE_DATA_WL{1'b0}} - (2 ** C_TEMPERATURE_DATA_WL-1)};
reg RX_period_signal;
reg RX_period_strobe_signal;
reg RX_sinchro_signal = 1'b0;
reg Strobe_curr_state = Strobe_state1;

always @* begin
	CLK_signal = CLK_IN; 
end


always @(posedge GSR_signal) begin
	GSR_signal <= 1'b1;
	#100;
	GSR_signal <= 1'b0;
	#0;
end

always @(posedge CLK_signal or posedge GSR_signal) begin
	if (GSR_signal == 1'b1) begin
		assign CLK_COUNTER_signal = CLK_signal;
	end if (CLK_signal == 1'b1) begin
		assign CLK_COUNTER_signal = CLK_COUNTER_signal + 1;
	end
end

always @* begin
	CLK_DIV_TX = CLK_COUNTER_signal[1];
	CLK_DIV_RX = CLK_COUNTER_signal[3];
	CLK_DIV_filter = CLK_COUNTER_signal[2];
end

if (C_SIMULATION) begin : GEN_SIMULATION
	always @(posedge GSR_signal or posedge CLK_COUNTER_signal[7]) begin 
		if (GSR_signal == 1'b1) begin
			START_CONTROL_TIME_signal <= 1'b0;
		end if (CLK_COUNTER_signal[7] == 1'b1) begin
			START_CONTROL_TIME_signal <= 1'b1;
		end
	end

	always @* begin 
		RX_period_signal = CLK_COUNTER_signal[8];
	end
end

if (!C_SIMULATION) begin : GEN_SIMULATION_NONE 
	always @(posedge GSR_signal or posedge CLK_COUNTER_signal[26]) begin
		if (GSR_signal == 1'b1) begin
			START_CONTROL_TIME_signal <= 1'b0;
		end if (CLK_COUNTER_signal[26] == 1'b1) begin
			START_CONTROL_TIME_signal <= 1'b1;
		end
	end

	always @* begin
		RX_period_signal = CLK_COUNTER_signal[24];
	end
end

always @* begin
	PGOOD_All_bus_signal[(C_LEDS_QUANTITY-1):17] = PGOOD_All_bus_IN[(C_LEDS_QUANTITY-1):17];
	PGOOD_All_bus_signal[16] = PGOOD_All_bus_IN[16] & PGOOD_All_bus_IN[C_LEDS_QUANTITY];
	PGOOD_All_bus_signal[15:0] = PGOOD_All_bus_IN[15:0];
end



always @(posedge GSR_signal or posedge CLK_DIV_filter) begin
	if (GSR_signal == 1'b1) begin
		PGOOD_filtered_signal[0] <= 1'b1;
	end if (CLK_DIV_filter == 1'b1) begin
		if (PGOOD_All_bus_signal != !{C_LEDS_QUANTITY{1'b0}}) begin
			PGOOD_filtered_signal[0] <= 1'b0;
		end else begin
			PGOOD_filtered_signal[0] <= 1'b1;
		end
	end
end

genvar i;
for (i = 1; i < (FILTER_LENGTH - 1); i = i + 1) begin: PGOOD_SHIFT_REGISTER
	always @(posedge GSR_signal or posedge CLK_DIV_filter) begin
		if (GSR_signal == 1'b1) begin
			PGOOD_filtered_signal[i] <= 1'b1;
		end else if (CLK_DIV_filter == 1'b1) begin
			PGOOD_filtered_signal[i] <= PGOOD_filtered_signal[i-1];
		end
	end
end	

always @(posedge GSR_signal or posedge CLK_signal) begin
	if (GSR_signal == 1'b1) begin
		CRASH_POWER_TRIG_signal <= 1'b0;
	end if (CLK_signal == 1'b1) begin
		if (PGOOD_filtered_signal == {FILTER_LENGTH{1'b0}} && START_CONTROL_TIME_signal == 1'b1 && CRASH_POWER_TRIG_signal == 1'b0) begin
			CRASH_POWER_TRIG_signal <= 1'b1;
		end
	end
end

always @* begin
	CRASH_signal = CRASH_POWER_TRIG_signal || CRASH_TEMP_TRIG_signal;
end

always @(posedge GSR_signal or posedge CRASH_POWER_TRIG_signal) begin
	if (GSR_signal == 1'b1) begin
		assign SDI_Data_signal = GSR_signal;
	end if (CRASH_POWER_TRIG_signal == 1'b1) begin
		assign SDI_Data_signal = !PGOOD_All_bus_signal;
	end
end

always @(posedge GSR_signal or posedge CLK_signal) begin
	if (GSR_signal == 1'b1) begin
		ENABLE_ALL_POWER_INV_signal <= 1'b0;
	end if (CLK_signal == 1'b1) begin
		assign ENABLE_ALL_POWER_signal = CRASH_signal;
	end
end

always @* begin
	ENABLE_ALL_POWER_signal = ENABLE_ALL_POWER_INV_signal;
end

assign EN_ANALOG_PWR_OUT = ENABLE_ALL_POWER_signal;
assign EN_DIGITAL_3V3_OUT = ENABLE_ALL_POWER_signal;
assign EN_5V0_POWER_OUT = ENABLE_ALL_POWER_signal;
assign EN_VCC_2V5_OUT = ENABLE_ALL_POWER_signal;
assign EN_VCC_1V0_INT_OUT = ENABLE_ALL_POWER_signal;
assign FPGA_PROG_B_OUT = !CRASH_signal;
assign LED_CPLD_0_RED_OUT = KEY_CPLD_IN[0] && !CRASH_POWER_TRIG_signal;
assign LED_CPLD_1_GREEN_OUT = KEY_CPLD_IN[1] && CRASH_POWER_TRIG_signal;
assign LED_CPLD_2_RED_OUT = KEY_CPLD_IN[2] && !CRASH_POWER_TRIG_signal;
assign LED_CPLD_3_GREEN_OUT = KEY_CPLD_IN[3] && CRASH_POWER_TRIG_signal;

reg Data_serial_counter_TX = 0;
always @(posedge GSR_signal or posedge CLK_DIV_TX) begin
	if (GSR_signal == 1'b1) begin
		LED_DRIVER_SDI_OUT <= 1'b0;
		LED_DRIVER_LE_signal <= 1'b0;
		TX_sinchro_signal <= 1'b0;
		Data_serial_counter_TX = C_LEDS_QUANTITY;
	end if (CLK_DIV_TX == 1'b0) begin
		if (TX_curr_mode == Run_state) begin /*РАЗОБРАТЬ строку 245*/
			if (Data_serial_counter_TX != 0) begin
				assign LED_DRIVER_SDI_OUT = SDI_Data_signal[Data_serial_counter_TX-1];
				TX_sinchro_signal <= 1'b1;
				Data_serial_counter_TX = Data_serial_counter_TX - 1;
			end else begin
				LED_DRIVER_SDI_OUT <= 1'b0;
				LED_DRIVER_LE_signal <= 1'b1;
				TX_sinchro_signal <= 1'b0;
				Data_serial_counter_TX = C_LEDS_QUANTITY;
			end
		end if (TX_curr_mode == Finish_state) begin
			LED_DRIVER_LE_signal <= 1'b0;
		end
	end
end

assign LED_DRIVER_CLK_OUT = CLK_DIV_TX & TX_sinchro_signal;
assign LED_DRIVER_LE_OUT = LED_DRIVER_LE_signal;

always @(posedge GSR_signal or posedge CLK_DIV_TX) begin
	if (GSR_signal == 1'b1) begin
		assign TX_curr_mode = Start_state;
	end if (CLK_DIV_TX == 1'b1) begin 
		case (TX_curr_mode)
			Stop_state: 
			if (CRASH_POWER_TRIG_signal == 1'b0) begin 
				assign TX_curr_mode = Stop_state;
			end else begin
				assign TX_curr_mode = Start_state;
			end

			Start_state:
			assign TX_curr_mode = Run_state;

			Run_state:
			if (LED_DRIVER_LE_signal == 1'b1) begin
				assign TX_curr_mode = Finish_state;
			end else begin 
				assign TX_curr_mode = Run_state;
			end

			Finish_state:
			if (CRASH_TEMP_TRIG_signal == 1'b1) begin
				assign TX_curr_mode = Finish_state;
			end else begin
				assign TX_curr_mode = Stop_state;
			end

			default:
			assign TX_curr_mode = Stop_state;
		endcase
	end
end	

always @(posedge GSR_signal or posedge CLK_signal) begin
	if (GSR_signal == 1'b1) begin 
		CRASH_TEMP_TRIG_signal <= 1'b0;
	end if (CLK_signal == 1'b1) begin
		if (Temperature_data_signal >= MAX_TEMP_CODE_CONST && CRASH_POWER_TRIG_signal == 1'b0) begin
			CRASH_TEMP_TRIG_signal <= 1'b1;
		end
	end
end

reg Data_serial_counter_RX = 0;
always @(posedge GSR_signal or posedge CLK_DIV_RX) begin 
	if (GSR_signal == 1'b1) begin
		assign Temp_sensor_CS_signal = 1'b1;
		assign RX_sinchro_signal = 1'b0;
		assign Data_serial_counter_RX = 0;
		assign Temperature_data_signal = {{C_TEMPERATURE_DATA_WL{1'b0}} - -(2 ** (C_TEMPERATURE_DATA_WL-1))};
	end if (CLK_DIV_RX == 1'b0) begin
		if (RX_curr_mode == Run_state) begin
			if (Data_serial_counter_RX != C_TEMP_SENSOR_PO_WL) begin
				assign Temp_sensor_CS_signal = 1'b0;
				assign RX_sinchro_signal = 1'b0;
				assign Data_serial_counter_RX = Data_serial_counter_RX + 1;
			end else begin
				assign Temp_sensor_CS_signal = 1'b1;
				assign RX_sinchro_signal = 1'b0;
				assign Data_serial_counter_RX = 0;
				assign Temperature_data_signal = Temp_sensor_PO_signal[(C_TEMP_SENSOR_PO_WL-1):(C_TEMP_SENSOR_PO_WL-C_TEMPERATURE_DATA_WL)];
			end
		end
	end
end

always @* begin
	Temp_sensor_SCK_signal = CLK_DIV_RX && RX_sinchro_signal;
end

assign Temp_sensor_SCK_OUT = Temp_sensor_SCK_signal;
assign Temp_sensor_CS_OUT = Temp_sensor_CS_signal;

always @(posedge GSR_signal or posedge Temp_sensor_SCK_signal) begin 
	if (GSR_signal == 1'b1) begin
		Temp_sensor_PO_signal <= 1'b0;
	end if (Temp_sensor_SCK_signal == 1'b1) begin
		assign Temp_sensor_PO_signal = Temp_sensor_SO_IN;
	end
end

generate
	for (i = 1; i < (C_TEMP_SENSOR_PO_WL-1); i = i + 1) begin: Temp_sensor_PO_SHIFT_REGISTER
		always @(posedge GSR_signal or posedge Temp_sensor_SCK_signal) begin
			if (GSR_signal == 1'b1) begin
				Temp_sensor_PO_signal[i] <= 1'b0;
			end if (Temp_sensor_SCK_signal == 1'b1) begin
				Temp_sensor_PO_signal[i] = Temp_sensor_PO_signal[i-1];
			end
		end
	end
endgenerate	

always @(posedge GSR_signal or posedge CLK_signal) begin
	if (GSR_signal == 1'b1) begin
		assign Strobe_curr_state = Strobe_state1;
	end if (CLK_signal == 1'b1) begin
		case (Strobe_curr_state)
			Strobe_state1:
			if (RX_period_signal == 1'b1 && CRASH_signal == START_CONTROL_TIME_signal == 1'b1) begin
				assign Strobe_curr_state = Strobe_state2;
			end else begin
				assign Strobe_curr_state = Strobe_state1;
			end

			Strobe_state2:
			if (RX_curr_mode == Start_state) begin
				assign Strobe_curr_state = Strobe_state3;
			end else begin
				assign Strobe_curr_state = Strobe_state2;
			end

			Strobe_state3:
			if (RX_sinchro_signal == 1'b1) begin
				assign Strobe_curr_state = Strobe_state3;
			end else begin
				assign Strobe_curr_state = Strobe_state1;
			end

			default:
			assign Strobe_curr_state =  Strobe_state1;
		endcase
	end
end

always @* begin
	RX_period_strobe_signal = (Strobe_curr_state == Strobe_state2) ? 1'b1 : 1'b0;
end

always @(posedge GSR_signal or posedge CLK_DIV_RX) begin
	assign RX_curr_mode = Stop_state;
	if (CLK_DIV_RX == 1'b1) begin
		case (RX_curr_mode)
			Stop_state:
			if (RX_period_strobe_signal == 1'b1) begin
				assign RX_curr_mode = Start_state;
			end else begin
				assign RX_curr_mode = Stop_state;
			end

			Start_state:
			assign RX_curr_mode = Run_state;

			Run_state:
			if (Temp_sensor_CS_signal == 1'b0) begin
				assign RX_curr_mode = Run_state;
			end else begin 
				assign RX_curr_mode = Finish_state;
			end

			Finish_state:
			assign RX_curr_mode = Stop_state;

			default:
			assign RX_curr_mode = Stop_state;
		endcase
	end
end

endmodule























