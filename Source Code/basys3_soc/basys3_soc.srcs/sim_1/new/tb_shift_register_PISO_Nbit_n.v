`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 16:47:23
// Design Name: 
// Module Name: tb_shift_register_PISO_Nbit_n
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_shift_register_PISO_Nbit_n();
    reg clk, reset_p;
    reg [7:0] d;
    reg shift_load;
    wire q;
    
    parameter data = 8'b10100011;
    
    shift_register_PISO_Nbit_n #(.N(8)) DUT(clk, reset_p, d, shift_load, q); 

   initial begin
        clk = 0;
        reset_p = 1;
        d = 0;
        shift_load = 0;
    end

    always #5 clk = ~clk;
    
    initial begin
        #10;
        reset_p = 0;
        d=data;
        #10;
        shift_load = 1;
        #70;
        $finish;        
    end 
endmodule
