`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/24 16:34:24
// Design Name: 
// Module Name: exam02_sequential_logic
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


module D_flip_flop_n(
    input d,
    input clk, reset_p, enable,
    output reg q);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) q = 0;
        else if(enable) q = d;
    end
endmodule

module D_flip_flop_p(
    input d,
    input clk, reset_p, enable,
    output reg q);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) q = 0;
        else if(enable) q = d;
    end
endmodule

module T_flip_flop_n(
    input clk, reset_p,
    input t,
    output reg q);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)q=0;
        else begin
            if(t)q=~q;
            else q=q;
        end
    end                   

endmodule

module T_flip_flop_p(
    input clk, reset_p,
    input t,
    output reg q);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)q=0;
        else begin
            if(t)q=~q;
            else q=q;
        end
    end                  
endmodule

module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count);
    
    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule




module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count);
    
    T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

module up_counter_p(
    input clk, reset_p, enable,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else if(enable)count = count + 1;
    end
endmodule

module up_counter_n(
    input clk, reset_p, enable,
    output reg [3:0] count);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else if(enable)count = count +1;
    end
endmodule

module down_counter_p(
    input clk, reset_p, enable,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else if(enable)count = count - 1;
    end
endmodule

module down_counter_n(
    input clk, reset_p, enable,
    output reg [3:0] count);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else if(enable)count = count - 1;
    end
endmodule

module bcd_upcounter_p(
    input clk, reset_p,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else begin
            if(count >= 9)count = 0;
            else count = count +1;
        end
    end
endmodule

module bcd_downcounter_p(
    input clk, reset_p,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 9;
        else begin
            if(count >= 10 | count == 0)count = 9;
            else count = count -1;
        end
    end
endmodule

module up_downcounter_p(
    input clk, reset_p,
    input up_down,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else begin
            if(up_down)begin
                count = count + 1;
            end
            else begin
                count = count -1;
            end
        end
    end
endmodule

module bcd_up_downcounter_p(
    input clk, reset_p,
    input up_down,
    output reg [3:0] count);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) count = 0;
        else begin
            if(up_down)begin
                if(count >= 9) count = 0;
                else count = count + 1;
                //if(count >= 9) count = 0;
            end
            else begin
                count = count -1;
                if(count == 0 | count >= 10) count = 9;
            end
        end
    end
endmodule

module ring_counter(
    input clk, reset_p,
    output reg [3:0] q);
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)q=4'b0001;
        else begin
            if(q == 4'b1000)q=4'b0001;
            else q = {q[2:0], 1'b0};
            //else q=q<<1;
        end
    end
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p) q=4'b0001;
//        else begin
//            case(q)
//                4'b0001: q = 4'b0010;
//                4'b0010: q = 4'b0100;
//                4'b0100: q = 4'b1000;
//                4'b1000: q = 4'b0001;
//                default: q = 4'b0001;
//            endcase
//        end
//    end
endmodule

//module edge_detector_p(
//    input clk, reset_p,
//    input cp,
//    output p_edge);
    
//    reg ff_cur, ff_old;
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p)begin
//            ff_cur<=0;
//            ff_old<=0;
//        end
//        else begin
            
//            ff_cur <= cp;
//            ff_old <= ff_cur;
//        end
//    end
    
//    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
//endmodule

module ring_counter_led(
    input clk, reset_p,
    output reg [15:0] led);
    
    reg [20:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1; //2의 비트수의 제곱만큼 분주 됨
                                                //2^21/10ns 주기
    wire clk_div_nedge;
    edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[20]), .n_edge(clk_div_nedge));                                            
                                                
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)led=16'b0000_0000_0000_0001;
        else if(clk_div_nedge)begin
            if(led == 16'b1000_0000_0000_0000)led=16'b1;
            else led = {led[14:0], 1'b0};
        end
    end
endmodule

module ring_counter_fnd(
    input clk, reset_p,
    output reg [3:0] com);
    
    reg [20:0] clk_div = 0; //레지스터에 0주는건 시뮬레이션에서만 가능, 회로에서는 레지스터에 0을 줄수없기때문 리셋으로 0줄수있음
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_nedge; //와이어에 0주는건 접지시키는것, 거기에 1들어가면 쇼트
    edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)com=4'b1110;
        else if(clk_div_nedge)begin
            if(com == 4'b0111)com=4'b1110;
            else com = {com[2:0], 1'b1};
        end
    end
endmodule

module edge_detector_p(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge);
    
    reg ff_cur, ff_old;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            ff_cur<=0;
            ff_old<=0;
        end
        else begin
            
            ff_cur <= cp;
            ff_old <= ff_cur;
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule

module edge_detector_n(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge);
    
    reg ff_cur, ff_old;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            ff_cur<=0;
            ff_old<=0;
        end
        else begin
            
            ff_cur <= cp;
            ff_old <= ff_cur;
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule

module shift_register_SISO_n(
    input clk, reset_p,
    input d,
    output q);
    
    reg [3:0] siso_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)siso_reg<=0;
        else begin
            siso_reg<={d, siso_reg[3:1]};
//            siso_reg[3]<=d;
//            siso_reg[2]<=siso_reg[3];
//            siso_reg[1]<=siso_reg[2];
//            siso_reg[0]<=siso_reg[1];
        end
    end
    assign q=siso_reg[0];
endmodule

module shift_register_SISO_Nbit_n #(parameter N=8)(
    input clk, reset_p,
    input d,
    output q);
    
    reg [N-1:0] siso_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)siso_reg<=0;
        else begin
            siso_reg<={d, siso_reg[N-1:1]};
//            siso_reg[3]<=d;
//            siso_reg[2]<=siso_reg[3];
//            siso_reg[1]<=siso_reg[2];
//            siso_reg[0]<=siso_reg[1];
        end
    end
    assign q=siso_reg[0];
endmodule

module shift_register_SISO_Nbit_msb_n #(parameter N=8)(
    input clk, reset_p,
    input d,
    output q);
    
    reg [N-1:0] siso_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)siso_reg<=0;
        else begin
            siso_reg<={siso_reg[N-2:0], d};
//            siso_reg[3]<=d;
//            siso_reg[2]<=siso_reg[3];
//            siso_reg[1]<=siso_reg[2];
//            siso_reg[0]<=siso_reg[1];
        end
    end
    assign q=siso_reg[N-1];
endmodule

module shift_register_SIPO_n(
    input clk, reset_p,
    input d,
    input rd_en, //read enable
    output [3:0] q);
    
    reg [3:0] sipo_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)sipo_reg<=0;
        else begin
            sipo_reg<={d, sipo_reg[3:1]};
        end
    end
    
    assign q=rd_en ? 4'bz : sipo_reg;
    //bufif0 {q[0], sipi_reg[0], rd_en);//3phase buffer
endmodule

module shift_register_SIPO_Nbit_n #(parameter N=8)(
    input clk, reset_p,
    input d,
    input rd_en, //read enable
    output [N-1:0] q);
    
    reg [N-1:0] sipo_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)sipo_reg<=0;
        else begin
            sipo_reg<={d, sipo_reg[N-1:1]};
        end
    end
    
    assign q=rd_en ? 'bz : sipo_reg;
    //bufif0 {q[0], sipi_reg[0], rd_en);//3phase buffer
endmodule

module shift_register_PISO_n(
    input clk, reset_p,
    input [3:0] d,
    input shift_load,
    output q);
    
    reg [3:0] piso_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)piso_reg<=0;
        else begin
            if(shift_load)begin
                piso_reg<={1'b0, piso_reg[3:1]};
            end
            else begin
                piso_reg = d;
            end
        end
    end
    assign q=piso_reg[0];
endmodule

module shift_register_PISO_Nbit_n #(parameter N=8)(
    input clk, reset_p,
    input [N-1:0] d,
    input shift_load,
    output q);
    
    reg [N-1:0] piso_reg;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)piso_reg<=0;
        else begin
            if(shift_load)begin
                piso_reg<={1'b0, piso_reg[N-1:1]};
            end
            else begin
                piso_reg = d;
            end
        end
    end
    assign q=piso_reg[0];
endmodule

module register_8bit_n(
    input [7:0] in_data,
    input clk, reset_p, wr_en, rd_en,    //기존 enable을 wr_en로 사용
    output [7:0] out_data);
    
    reg [7:0] register;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) register = 0;
        else if(wr_en) register = in_data;
    end
    assign out_data = rd_en ? register : 'bz; //rd_en이 1일때 출력, 0일때 임피던스
endmodule

module register_Nbit_n #(parameter N=8)(
    input [N-1:0] in_data,
    input clk, reset_p, wr_en, rd_en,    //기존 enable을 wr_en로 사용
    output [N-1:0] out_data);
    
    reg [N-1:0] register;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) register = 0;
        else if(wr_en) register = in_data;
    end
    assign out_data = rd_en ? register : 'bz; //rd_en이 1일때 출력, 0일때 임피던스
endmodule

module sram_8bit_1024(  //메모리 이기때문에 리셋 없음
    input clk,
    input wr_en, rd_en, 
    input [9:0] addr, 
    inout [7:0] data);  //inout input으로도 쓰고 out으로도 사용 
                        //input으로 사용할때는 임피던스로 외부입력 끊어야한다
    reg [7:0] mem[0:1023];  //verilog의 배열 선언 1024개
    
    always @(posedge clk)if(wr_en) mem[addr] = data; //wr_en이 1이면 mem[인덱스]에 data 저장
    assign data = rd_en ? mem[addr] : 'bz; //rd_en이 1일때만 출력
                                           //복사를 위해선 임시 저장할 버퍼필요     
endmodule













