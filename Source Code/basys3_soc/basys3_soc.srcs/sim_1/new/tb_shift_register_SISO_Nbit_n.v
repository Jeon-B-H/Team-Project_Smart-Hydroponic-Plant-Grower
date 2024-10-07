`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/15 11:24:03
// Design Name: 
// Module Name: tb_shift_register_SISO_Nbit_n
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


module tb_shift_register_SISO_Nbit_n();

    reg clk, reset_p;
    reg d;
    wire q;
    
    parameter data = 8'b11010011;
    
    shift_register_SISO_Nbit_n #(.N(8)) DUT(    //DUT=design under test
        .clk(clk), .reset_p(reset_p),
        .d(d),
        .q(q));
    
    initial begin 
        clk=0;
        reset_p=1;
        d=data[0];
    end
    
    always #5 clk = ~clk; //#=time delay, 5ns, edit 1th code, 5ns=0 -> 5ns=1 =>10ns clk
    integer i;
    initial begin
        #10;
        reset_p = 0;
        for(i=0;i<8;i=i+1)begin
            d=data[i]; #10;
        end
//        d = data[0]; #10;
//        d = data[1]; #10;
//        d = data[2]; #10;
//        d = data[3]; #10;
        #70;
        $finish;
    end 
    
endmodule



