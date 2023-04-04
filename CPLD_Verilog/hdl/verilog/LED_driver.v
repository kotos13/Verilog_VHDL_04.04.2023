/*--------------------------------------------------------------------------------
LED driver STM STP16D05 simulation model
--------------------------------------------------------------------------------*/

`timescale 1 ns / 1 ps

module LED_driver 
#( 
 parameter C_N = 16  // разрядность 
) 
( 
 input wire LED_Clk, 
 input wire LED_LE, 
 input wire LED_SDI, 
 input wire LED_OE, 
 output wire LED_SDO, 
 output reg [C_N-1:0] LED_PO = 0 
); 
 
reg [C_N-1:0] PO_signal = 0; 
reg RST_signal = 1'b0; 
 
always @(posedge LED_Clk) begin 
 if (RST_signal == 1'b1) begin 
  PO_signal[0] <= 1'b0; 
 end else begin 
  PO_signal[0] <= LED_SDI; 
 end 
end 
 
genvar i; 
generate 
 for (i = 1; i < C_N; i = i + 1) begin : SHIFT_REGISTER 
  always @(posedge LED_Clk) begin 
   if (RST_signal == 1'b1) begin 
    PO_signal[i] <= 1'b0; 
   end else begin 
    PO_signal[i] <= PO_signal[i-1]; 
   end 
  end 
 end 
endgenerate 
 
always @(LED_LE, LED_OE, PO_signal) begin 
 if (LED_OE == 1'b1) begin 
  LED_PO <= 0; 
 end else if (LED_LE == 1'b1) begin 
  LED_PO <= PO_signal; 
 end 
end 
 
assign LED_SDO = PO_signal[C_N-1]; 
 
endmodule
