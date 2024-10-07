`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 11:19:13
// Design Name: 
// Module Name: clock_library
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

//100분주 기
module clock_div_100(
    input clk, reset_p,
    output clk_div_100,
    output clk_div_100_nedge);
    
    reg [6:0] cnt_sysclk;   //100까지 세는 카운터,7비트 필요
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else begin
                if(cnt_sysclk >= 99) cnt_sysclk = 0;
                else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    assign clk_div_100 = (cnt_sysclk < 50) ? 0 : 1;
    
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_100),
        .n_edge(clk_div_100_nedge));
    
endmodule

//1000분주기
module clock_div_1000(
    input clk, reset_p,
    input clk_source, //1us
    output clk_div_1000,
    output clk_div_1000_nedge);
    
    reg [9:0] cnt_clksource;   //1000까지 세는 카운터,10비트 필요
    
    wire clk_source_nedge;
    edge_detector_n ed_source(
        .clk(clk), .reset_p(reset_p), .cp(clk_source),
        .n_edge(clk_source_nedge));
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_clksource = 0;
        else if(clk_source_nedge)begin
                if(cnt_clksource >= 999) cnt_clksource = 0;
                else cnt_clksource = cnt_clksource + 1;
        end
    end
    
    assign clk_div_1000 = (cnt_clksource < 500) ? 0 : 1;
    
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_1000),
        .n_edge(clk_div_1000_nedge));
    
endmodule

//60분주기
module clock_div_60(
    input clk, reset_p,
    input clk_source,
    output clk_div_60,
    output clk_div_60_nedge);
    
    reg [5:0]/*integer*/ cnt_clksource;    //32비트, 남는건 상관없음
    
    wire clk_source_nedge;
    edge_detector_n ed_source(
        .clk(clk), .reset_p(reset_p), .cp(clk_source),
        .n_edge(clk_source_nedge));
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_clksource = 0;
        else if(clk_source_nedge)begin
                if(cnt_clksource >= 59) cnt_clksource = 0;
                else cnt_clksource = cnt_clksource + 1;
        end
    end
    
    assign clk_div_60 = (cnt_clksource < 30) ? 0 : 1;
    
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_60),
        .n_edge(clk_div_60_nedge));
endmodule


module counter_bcd_60(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] bcd1, bcd10);

    wire clk_time_nedge;
        
    edge_detector_n  ed_clk(
        .clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge));
        
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            bcd1 = 0;
            bcd10 = 0;
        end
        else if(clk_time_nedge) begin
            if(bcd1 >= 9) begin
                bcd1 = 0;
                if(bcd10 >=5) bcd10 = 0;
                else bcd10 = bcd10 +1;
            end
            else bcd1 = bcd1 + 1;
         end
    end

endmodule



module loadable_counter_bcd_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] load_bcd1, load_bcd10,
    output reg [3:0] bcd1, bcd10);

    wire clk_time_nedge;
    edge_detector_n ed_clk(
        .clk(clk), .reset_p(reset_p), .cp(clk_time),
        .n_edge(clk_time_nedge));
        
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            bcd1 = 0;
            bcd10 = 0;
        end
        else begin
            if(load_enable)begin
                bcd1 = load_bcd1;
                bcd10 = load_bcd10;
            end
            else if(clk_time_nedge)begin
                if(bcd1 >= 9)begin
                    bcd1 = 0;
                    if(bcd10 >= 5)bcd10 = 0;
                    else bcd10 = bcd10 + 1;
                end
                else bcd1 = bcd1 + 1;
            end
        end  
    end

endmodule




module counter_bcd_60_clear(
    input clk, reset_p,
    input clk_time,
    input clear,
    output reg [3:0] bcd1, bcd10);

    wire clk_time_nedge;
        
    edge_detector_n  ed_clk(
        .clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge));
        
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            bcd1 = 0;
            bcd10 = 0;
        end
        else begin
            if(clear) begin
                bcd1 = 0;
                bcd10 = 0;
            end
            else if(clk_time_nedge) begin
                if(bcd1 >= 9) begin
                    bcd1 = 0;
                    if(bcd10 >=5) bcd10 = 0;
                 else bcd10 = bcd10 +1;
                end
                else bcd1 = bcd1 + 1;
             end
         end
    end

endmodule


module clock_div_10(
    input clk, reset_p,
    input clk_source,
    output clk_div_10,
    output clk_div_10_nedge);
    
    reg [3:0]/*integer*/ cnt_clksource;    //32비트, 남는건 상관없음
    
    wire edge_clk_source;
     edge_detector_n ed_0(
        .clk(clk), .reset_p(reset_p), .cp(clk_source),
        .n_edge(edge_clk_source));
    
    always @(negedge clk or posedge reset_p) begin
            if(reset_p) cnt_clksource = 0;
            else if(edge_clk_source) begin
                  if(cnt_clksource >= 9) cnt_clksource = 0;
                  else cnt_clksource = cnt_clksource + 1;
            end
    end
    
    assign clk_div_10 = (cnt_clksource < 5)? 0 : 1;
    
    
    edge_detector_n ed_1(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_10),
        .n_edge(clk_div_10_nedge));
endmodule






module counter_bcd_100_clear(
    input clk, reset_p,
    input clk_time,
    input clear,
    output reg [3:0] bcd1, bcd10);

    wire clk_time_nedge;
        
    edge_detector_n  ed_clk(
        .clk(clk), .reset_p(reset_p), .cp(clk_time), .n_edge(clk_time_nedge));
        
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            bcd1 = 0;
            bcd10 = 0;
        end
        else begin
            if(clear) begin
                bcd1 = 0;
                bcd10 = 0;
            end
            else if(clk_time_nedge) begin
                if(bcd1 >= 9) begin
                    bcd1 = 0;
                    if(bcd10 >=9) bcd10 = 0;
                 else bcd10 = bcd10 +1;
                end
                else bcd1 = bcd1 + 1;
             end
         end
    end

endmodule



module loadable_down_counter_bcd_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] load_bcd1, load_bcd10,  //덮어쓰기 로드를 받기위한 입력
    output reg [3:0] bcd1, bcd10,
    output reg dec_clk);

    wire clk_time_nedge;
    edge_detector_n ed_clk(
        .clk(clk), .reset_p(reset_p), .cp(clk_time),
        .n_edge(clk_time_nedge));

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin    //리셋 우선
            bcd1 = 0;
            bcd10 = 0;
            dec_clk = 0;
        end
        else begin 
            if(load_enable)begin
                bcd1 = load_bcd1;
                bcd10 = load_bcd10;
            end
            else if(clk_time_nedge)begin
                if(bcd1 == 0)begin
                    bcd1 = 9;
                    if(bcd10 == 0)begin
                        bcd10 = 5;
                        dec_clk = 1;
                    end
                    else bcd10 = bcd10 - 1;
                end
                else bcd1 = bcd1 - 1;
            end
            else dec_clk = 0;   //one cycle pulse 가능
        end
    end
endmodule



module sr04_div_58(
    input clk, reset_p,
    input clk_usec, cnt_e,
    output reg [11:0] cm);  
    
    reg [5:0]/*integer*/ cnt;    //32비트, 남는건 상관없음
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) begin
               cnt = 0;
               cm = 0;
        end      
        else if(clk_usec)begin
                if(cnt_e) begin 
                     if(cnt >= 57) begin 
                            cnt = 0;
                            cm = cm +1;
                      end
                     else cnt = cnt + 1;
                end
        end
        else if(!cnt_e) begin
             cnt = 0;
             cm = 0;
        end
    end    
endmodule

