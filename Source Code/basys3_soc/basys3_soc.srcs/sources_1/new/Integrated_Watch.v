`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/25 16:31:51
// Design Name: 
// Module Name: Integrated_Watch
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


module Integrated_Watch(
    input clk, reset_p,
    input btn[3:0],
    input btn4,
    output [3:0] com,
    output [7:0] seg_7, led_debug);
    
    // declare state parameter.
    parameter S_CLOCK                       = 3'b001;
    parameter S_STOP_WATCH              =  3'b010;
    parameter S_COOKING_TIMER           = 3'b100;
    
    // For Test
    assign led_debug = state;
    
    // Get One Cycle pulse of button.
    wire clk_btn0, clk_btn1, clk_btn2, clk_btn3, clk_btn4;
    button_cntr btn_cntr_btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(clk_btn0));
    button_cntr btn_cntr_btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(clk_btn1));
    button_cntr btn_cntr_btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(clk_btn2));
    button_cntr btn_cntr_btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(clk_btn3));
    button_cntr btn_cntr_btn4(.clk(clk), .reset_p(reset_p), .btn(btn4), .btn_pedge(clk_btn4));
    
    // declare state, next_state variable.
    reg [2:0] state, next_state;
    
    // declare common button variable.
    reg [2:0] clock_button, stop_watch_button;
    reg [3:0] cooking_time_button;  
    
    // When does it change to the next state?
    always @(negedge clk or posedge reset_p) begin
            if(reset_p) state = S_CLOCK;
            else state = next_state;
    end
    
    // What conditions do I have to meet to move to the next state?
    always @(posedge clk or posedge reset_p) begin
           if(reset_p) begin
                next_state = S_CLOCK;  
                clock_button = 3'b000;
                stop_watch_button = 3'b000;
                cooking_time_button = 4'b0000;   
           end
           else begin
                 if(clk_btn0) begin
                case(state) 
                    S_CLOCK : next_state <= S_STOP_WATCH;
                    S_STOP_WATCH : next_state <= S_COOKING_TIMER;
                    S_COOKING_TIMER : next_state <= S_CLOCK;
                    default : next_state <= next_state;
                endcase
            end 
            else begin
                next_state <= state;
            end

            // Update button states based on current state
            case(state) 
                S_CLOCK : begin
                    clock_button[0] <= clk_btn1;
                    clock_button[1] <= clk_btn2;
                    clock_button[2] <= clk_btn3;
                end
                
                S_STOP_WATCH : begin
                    stop_watch_button[0] <= clk_btn1;
                    stop_watch_button[1] <= clk_btn2;
                    stop_watch_button[2] <= clk_btn3;
                end
                
                S_COOKING_TIMER : begin
                    cooking_time_button[0] <= clk_btn1;
                    cooking_time_button[1] <= clk_btn2;
                    cooking_time_button[2] <= clk_btn3;
                    cooking_time_button[3] <= clk_btn4;
                end
            endcase     
           end     
    end
    
    
      // Module outputs
    wire [3:0] com_clock, com_stop, com_cook;
    wire [7:0] seg_7_clock, seg_7_stop, seg_7_cook;
    
    // Module instantiations
    watch_top watch_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn(clock_button), 
        .com(com_clock), 
        .seg_7(seg_7_clock)
    );
    
    stop_watch_top stop_watch_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn(stop_watch_button), 
        .com(com_stop), 
        .seg_7(seg_7_stop)
    );
    
    cook_timer_top cook_timer_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn(cooking_time_button), 
        .com(com_cook), 
        .seg_7(seg_7_cook)
    );
    
    // Output selection based on current state
    assign com = (state == S_CLOCK) ? com_clock :
                 (state == S_STOP_WATCH) ? com_stop : com_cook;
    assign seg_7 = (state == S_CLOCK) ? seg_7_clock :
                   (state == S_STOP_WATCH) ? seg_7_stop : seg_7_cook;
  
endmodule




module Integrated_Watch_test(
    input clk, reset_p,
    input [3:0] btn,
    input btn4,
    output [3:0] com,
    output [7:0] seg_7, 
    output [2:0] led_debug
);
    
    // declare state parameter.
    parameter S_CLOCK         = 3'b001;
    parameter S_STOP_WATCH    = 3'b010;
    parameter S_COOKING_TIMER = 3'b100;
    
    // For Test
    assign led_debug = state;
    
    // Get One Cycle pulse of button.
    wire clk_btn0, clk_btn1, clk_btn2, clk_btn3, clk_btn4;
    button_cntr btn_cntr_btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(clk_btn0));
    button_cntr btn_cntr_btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(clk_btn1));
    button_cntr btn_cntr_btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(clk_btn2));
    button_cntr btn_cntr_btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(clk_btn3));
    button_cntr btn_cntr_btn4(.clk(clk), .reset_p(reset_p), .btn(btn4), .btn_pedge(clk_btn4));
    
    // declare state, next_state variable.
    reg [2:0] state, next_state;
    
    // State transition and button processing logic
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            state <= S_CLOCK;
            next_state <= S_CLOCK;
        end
        else begin
            state <= next_state;
            if(clk_btn0) begin
                case(state) 
                    S_CLOCK : next_state <= S_STOP_WATCH;
                    S_STOP_WATCH : next_state <= S_COOKING_TIMER;
                    S_COOKING_TIMER : next_state <= S_CLOCK;
                    default : next_state <= next_state;
                endcase
            end 
        end
    end
    
    // Module outputs
    wire [3:0] com_clock, com_stop, com_cook;
    wire [7:0] seg_7_clock, seg_7_stop, seg_7_cook;
    
    // Module instantiations with direct button connections
    watch_top watch_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn({clk_btn3, clk_btn2, clk_btn1}), 
        .com(com_clock), 
        .seg_7(seg_7_clock)
    );
    
    stop_watch_top stop_watch_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn({clk_btn3, clk_btn2, clk_btn1}), 
        .com(com_stop), 
        .seg_7(seg_7_stop)
    );
    
    cook_timer_top cook_timer_mode (
        .clk(clk), 
        .reset_p(reset_p), 
        .btn({clk_btn4, clk_btn3, clk_btn2, clk_btn1}), 
        .com(com_cook), 
        .seg_7(seg_7_cook)
    );
    
    // Output selection based on current state
    assign com = (state == S_CLOCK) ? com_clock :
                 (state == S_STOP_WATCH) ? com_stop : com_cook;
    assign seg_7 = (state == S_CLOCK) ? seg_7_clock :
                   (state == S_STOP_WATCH) ? seg_7_stop : seg_7_cook;

endmodule