/*--------------------------------------------------------------------------------
Temperature sensor MAX6630MUT-T simulation model
--------------------------------------------------------------------------------*/

`timescale 1 ps / 1 ps

module Temp_sensor_model #(  
    parameter C_TEMP_SENSOR_PO_WL = 16,  
    parameter C_TEMP_SENSOR_DATA_WL = 13  
)(  
    input wire [C_TEMP_SENSOR_DATA_WL-1:0] Temp_sensor_Data_IN,  
    input wire Temp_sensor_SCK_IN,  
    input wire Temp_sensor_CS_IN,  
    output reg Temp_sensor_SO_OUT  
);  
  
reg [C_TEMP_SENSOR_PO_WL-1:0] Temp_sensor_PO_Buf_signal = {2'bXX, {C_TEMP_SENSOR_PO_WL-2{1'b0}}}; 
  
initial begin  
    Temp_sensor_PO_Buf_signal[2] <= 0;  
    Temp_sensor_PO_Buf_signal[1:0] <= 2'bxx;  
end  
 
integer Data_serial_counter;  
always @(Temp_sensor_CS_IN or Temp_sensor_SCK_IN or Temp_sensor_Data_IN) begin  
    if (Temp_sensor_CS_IN == 1'b0) begin  
        Temp_sensor_PO_Buf_signal[C_TEMP_SENSOR_PO_WL-1:(C_TEMP_SENSOR_PO_WL-C_TEMP_SENSOR_DATA_WL)] <= Temp_sensor_Data_IN;  
        Data_serial_counter = C_TEMP_SENSOR_PO_WL-1;  
        #80; // delay for 80 ns  
        assign Temp_sensor_SO_OUT = Temp_sensor_PO_Buf_signal[Data_serial_counter];  
        while (Temp_sensor_CS_IN == 1'b0) begin  
            @(negedge Temp_sensor_SCK_IN);  
            #80; // delay for 80 ns  
            assign Temp_sensor_SO_OUT = Temp_sensor_PO_Buf_signal[Data_serial_counter-1];
            Data_serial_counter = Data_serial_counter - 1;  
            if (Data_serial_counter == 0) begin  
                Data_serial_counter = C_TEMP_SENSOR_PO_WL;  
            end 
        end  
    end  
end  
endmodule