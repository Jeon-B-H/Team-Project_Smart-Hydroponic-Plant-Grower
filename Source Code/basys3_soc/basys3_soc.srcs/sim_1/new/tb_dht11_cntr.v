`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 12:15:27
// Design Name: 
// Module Name: tb_dht11_cntr
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


module tb_dht11_cntr();

    parameter [7:0] humi_data = 8'd80;
    parameter [7:0] tmpr_data = 8'd30;
    parameter [7:0] check_sum = humi_data + tmpr_data; 
    parameter [39:0] data = {humi_data, 8'b0, tmpr_data, 8'b0, check_sum};
    // 앞서 보낸 8bit 4개 데이터 를 더해서 
    // 통신간에 에러가 발생했는 지 여부 확인

    // Set type of input & output
    reg clk, reset_p; 
    wire [7:0] humidity, temperature;
    
    // tri1 : pull-up 저항이 달려있는 wire
    // tri0 : pull-down 저항이 달려있는 wire
    // 임피던스를 출력하면 1이 출력한다.
    tri1 dht11_data;

   
    // dht11_data는 inout이기 때문에 
    // 일단 wire형으로 선언하고,
    // wr_en 값에 따라 dht 데이터를 보낼지, 임피던스 출력을 보낸다.
    // wr_en = 1 이면 data_buffer;
    reg data_buffer, wr_en;  
    assign dht11_data = wr_en ? data_buffer : 'bz;
    
    
    // Create instance
    dht11_cntr DUT(.clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature) );

    // initialization.
    initial begin
        clk = 0;
        reset_p = 1;
        wr_en = 0;
    end
    
    // set clock pulse
    always #5 clk = ~clk;
    
     integer i;
    
    // processing of simulation.
    initial begin
        #10;
        reset_p = 0; #10;
        
        // wait 문은 조건문이 거짓인 동안 반복문 처럼 기다림
        // 1단계) wait for negative edge
        wait(!dht11_data);
        
        // 2단계) wait for positive edge
        wait(dht11_data);
        
        // 3단계) 20us를 기다렸다가 
        // 80us 동안 dth_data = 0을 출력
        #20_000;
        data_buffer = 0; wr_en = 1; #80_000;
        
         // 4단계) 80us 동안 dth_data = 'bz 출력
        wr_en = 0; #80_000;
        
        //  5단계) DHT에서 Basys3 으로 데이터 보내기.
        for(i=0; i<40; i= i+1) begin
               wr_en = 1; data_buffer = 0; #50_000;
     
                 // dht_data 값을 0->1로 변환   
                data_buffer = 1;     
                if(data[39-i]) #70_000;
                else #29_000;
        end     
        
         wr_en = 1; data_buffer = 0; #10;
         wr_en = 0; #10_000;
         
         $finish;
    end 
    
    
endmodule
