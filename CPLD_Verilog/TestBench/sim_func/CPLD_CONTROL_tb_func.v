`timescale 1 ns / 1 ps

module CPLD_CONTROL_tb_func #(
    parameter C_SIMULATION_TB = 1'b1,
    parameter C_LEDS_QUANTITY_TB = 24,
    parameter C_CRASH_TYPE_TB = 1,
    parameter C_TEMP_SENSOR_PO_WL_TB = 16,
    parameter C_TEMP_SENSOR_DATA_WL_TB = 13,
    parameter real C_MAX_TEMP_TB = 40.0
)();

    localparam CLK_PERIOD_TB_const = 25;
    reg CLK_TB_signal = 1'b0;
    reg [C_LEDS_QUANTITY_TB+1-1:0]Test_PGOOD_All_bus_TB_signal = {C_LEDS_QUANTITY_TB{1'b0}};
    reg [3:0]Test_KEY_CPLD_TB_signal;
    wire EN_Power_TB_signal;

    wire LED_Clk_TB_signal;
    wire LED_LE_TB_signal;
    wire LED_SDI_TB_signal;

    wire Temp_sensor_SO_TB_signal;
    wire Temp_sensor_CS_TB_signal;
    wire Temp_sensor_SCK_TB_signal;
    reg [C_TEMP_SENSOR_DATA_WL_TB-1:0] Temp_sensor_Data_TB_signal = {C_TEMP_SENSOR_DATA_WL_TB-1{1'b0}};

    CPLD_CONTROL #(
        .C_SIMULATION(C_SIMULATION_TB),
        .C_LEDS_QUANTITY(C_LEDS_QUANTITY_TB),
        .C_TEMP_SENSOR_PO_WL(C_TEMP_SENSOR_PO_WL_TB),
        .C_TEMPERATURE_DATA_WL(C_TEMP_SENSOR_DATA_WL_TB),
        .C_MAX_TEMP(C_MAX_TEMP_TB)
    ) CPLD_CONTROL_inst (
        .CLK_IN(CLK_TB_signal),
        .PGOOD_All_bus_IN(Test_PGOOD_All_bus_TB_signal),
        .KEY_CPLD_IN(Test_KEY_CPLD_TB_signal),
        .Temp_sensor_SO_IN(Temp_sensor_SO_TB_signal),

        .EN_ANALOG_PWR_OUT(EN_Power_TB_signal),
        .EN_DIGITAL_3V3_OUT(),
        .EN_5V0_POWER_OUT(),
        .EN_VCC_1V0_INT_OUT(),
        .EN_VCC_2V5_OUT(),

        .LED_CPLD_0_RED_OUT(),
        .LED_CPLD_1_GREEN_OUT(),
        .LED_CPLD_2_RED_OUT(),
        .LED_CPLD_3_GREEN_OUT(),

        .LED_DRIVER_CLK_OUT(LED_Clk_TB_signal),
        .LED_DRIVER_SDI_OUT(LED_SDI_TB_signal),
        .LED_DRIVER_LE_OUT(LED_LE_TB_signal),

        .Temp_sensor_CS_OUT(Temp_sensor_CS_TB_signal),
        .Temp_sensor_SCK_OUT(Temp_sensor_SCK_TB_signal),

        .FPGA_PROG_B_OUT()
    );

    LED_driver #(
        .C_N(C_LEDS_QUANTITY_TB)
    ) RTL_LED_driver (
        .LED_Clk(LED_Clk_TB_signal),
        .LED_LE(LED_LE_TB_signal),
        .LED_OE(1'b0),
        .LED_SDI(LED_SDI_TB_signal),
        .LED_SDO(),
        .LED_PO()
    );

    Temp_sensor_model #(
        .C_TEMP_SENSOR_PO_WL(C_TEMP_SENSOR_PO_WL_TB),
        .C_TEMP_SENSOR_DATA_WL(C_TEMP_SENSOR_DATA_WL_TB)
    ) Behavioral_Temp_sensor_model(  
        .Temp_sensor_Data_IN(Temp_sensor_Data_TB_signal),
        .Temp_sensor_SCK_IN(Temp_sensor_SCK_TB_signal),
        .Temp_sensor_CS_IN(Temp_sensor_CS_TB_signal),
        .Temp_sensor_SO_OUT(Temp_sensor_SO_TB_signal)
    );

    initial begin
        #(CLK_PERIOD_TB_const / 2);
        CLK_TB_signal <= ~CLK_TB_signal;
    end

    if ((C_CRASH_TYPE_TB == 0) || (C_CRASH_TYPE_TB == 2)) begin 
        always @(*) begin
            if (C_CRASH_TYPE_TB == 0 || C_CRASH_TYPE_TB == 2) begin
                Test_PGOOD_All_bus_TB_signal <= 32'h00000000;
                #3;
                Test_PGOOD_All_bus_TB_signal <= 32'hFFFFFFFF;
                #7;
                Test_PGOOD_All_bus_TB_signal <= 32'hBFFFFFFE;
                @(posedge EN_Power_TB_signal);
                #5;
                Test_PGOOD_All_bus_TB_signal <= 32'h00000000;
            end
        end
    end 

    always @(*) begin
        #5;
        if (C_CRASH_TYPE_TB == 0) begin
            Temp_sensor_Data_TB_signal <= {C_TEMP_SENSOR_DATA_WL_TB{1'b0}} + ((C_MAX_TEMP_TB - 1.0) / 0.0625);
        end else begin
            Temp_sensor_Data_TB_signal <= {C_TEMP_SENSOR_DATA_WL_TB{1'b0}} + ((C_MAX_TEMP_TB + 1.0) / 0.0625);
        end
    end

    if (C_CRASH_TYPE_TB == 1'b1) begin
        always @(*) begin
            Test_PGOOD_All_bus_TB_signal <= 32'h00000000;
            #3;
            Test_PGOOD_All_bus_TB_signal <= 32'hFFFFFFFF;
            if (EN_Power_TB_signal == 1'b1) begin
                #5;
                Test_PGOOD_All_bus_TB_signal <= 32'h00000000;
            end
        end
    end

    always @(*) begin
        #5;
        Temp_sensor_Data_TB_signal <= ((C_MAX_TEMP_TB-1.0) / 0.0625);
        #25;
        Temp_sensor_Data_TB_signal <= ((C_MAX_TEMP_TB+1.0) / 0.0625);
    end

    always @(*) begin
        Test_KEY_CPLD_TB_signal <= 4'b1111;
        #4;
        Test_KEY_CPLD_TB_signal <= 4'b1110;
        #1;
        Test_KEY_CPLD_TB_signal <= 4'b1100;
        #1;
        Test_KEY_CPLD_TB_signal <= 4'b1001;
        #1;
        Test_KEY_CPLD_TB_signal <= 4'b0011;
        #1;
        Test_KEY_CPLD_TB_signal <= 4'b0111;
        #1;
        Test_KEY_CPLD_TB_signal <= 4'b1111;
    end
endmodule