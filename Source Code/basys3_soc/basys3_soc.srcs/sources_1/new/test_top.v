`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 14:15:32
// Design Name: 
// Module Name: test_top
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


module board_test_top(
    input [15:0] switch, 
    output [15:0] led);
    
    assign led = switch;
    
endmodule

module fnd_test_top(    //보드에 연결되는 것들(XDC포함)
    input clk, reset_p,
    input [15:0] switch,
    output [3:0] com,
    output [7:0] seg_7);
    
    fnd_cntr FND (.clk(clk), .reset_p(reset_p), .value(switch), .com(com), .seg_7(seg_7));   //fnd_cntr에 연결
    
endmodule

module watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Button 은 누르기 전 0
    // Button 은 누른 후 1
    // btn_node : One cycle pulse of mode button
    // btn_sec : One cycle pulse of second button
    // btn_min : One cycle pulse of minute button
     wire btn_mode; 
     wire btn_sec; 
     wire btn_min; 
     
     // set_watch는 현재의 모드 변수
     // inc_sec : 
     // inc_min
     wire set_watch;
     wire inc_sec, inc_min;
     
     // clk_usec : 1usec 마다 
     wire clk_usec, clk_msec, clk_sec, clk_min;
     
     wire [3:0] sec1, sec10;
     wire [3:0] min1, min10;
     
     wire [15:0] value;
     
     // Chattering 문제점을 보완한 button control
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
  
//  // btn_mode의 누름 을 감지하여 
//     edge_detector_n  ed_btn0(
//        .clk(clk), .reset_p(reset_p), .cp(btn[0]), .n_edge(btn_mode));
    
//    // Button1 : 
//     edge_detector_n ed_btn1(
//        .clk(clk), .reset_p(reset_p), .cp(btn[1]), .n_edge(btn_sec));
        
//    // Button2 : 
//     edge_detector_n  ed_btn2(
//        .clk(clk), .reset_p(reset_p), .cp(btn[2]), .n_edge(btn_min));  
   
   // Button 0을 통해 Watch Mode 결정
   T_flip_flop_p t_mode(.clk(clk), .reset_p(reset_p),  .t(btn_mode), .q(set_watch));
   
   // MUX
   // 
   assign inc_sec = set_watch? btn_sec : clk_sec;
   assign inc_min = set_watch? btn_min : clk_min;
    
    // Prescaler
    clock_div_100 usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));
    clock_div_1000 sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));   
    clock_div_60 min_clk(.clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));
    
    // Get Information of second and minute    
    counter_bcd_60 counter_sec (.clk(clk), .reset_p(reset_p), .clk_time(inc_sec), .bcd1(sec1), .bcd10(sec10));
    
    counter_bcd_60 counter_min (.clk(clk), .reset_p(reset_p), .clk_time(inc_min), .bcd1(min1), .bcd10(min10));

    
    // Print FND
    assign value = {min10, min1, sec10, sec1};
    
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule



module board_test_top(
    input [15:0] switch, 
    output [15:0] led);
    
    assign led = switch;
    
endmodule

module fnd_test_top(    //보드에 연결되는 것들(XDC포함)
    input clk, reset_p,
    input [15:0] switch,
    output [3:0] com,
    output [7:0] seg_7);
    
    fnd_cntr FND (.clk(clk), .reset_p(reset_p), .value(switch), .com(com), .seg_7(seg_7));   //fnd_cntr에 연결
    
endmodule






module loadable_watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7);
    
    wire btn_mode;
    wire btn_sec;
    wire btn_min;
    wire set_watch;    
    wire inc_sec, inc_min;
    wire clk_usec, clk_msec, clk_sec, clk_min;
    
    
    
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
    
    T_flip_flop_p t_mode(.clk(clk), .reset_p(reset_p), .t(btn_mode), .q(set_watch));
    
    wire watch_load_en, set_load_en;
    edge_detector_n ed_source(
        .clk(clk), .reset_p(reset_p), .cp(set_watch),
        .n_edge(watch_load_en), .p_edge(set_load_en));
    
    assign inc_sec = set_watch ? btn_sec : clk_sec;
    assign inc_min = set_watch ? btn_min : clk_min;

    clock_div_100 usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_usec), .clk_div_1000(clk_msec));
    clock_div_1000 sec_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));
    clock_div_60 min_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(inc_sec), .clk_div_60_nedge(clk_min));
        
    loadable_counter_bcd_60 sec_watch(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_sec),
        .load_enable(watch_load_en),
        .load_bcd1(set_sec1), .load_bcd10(set_sec10),
        .bcd1(watch_sec1), .bcd10(watch_sec10));
    
    loadable_counter_bcd_60 min_watch(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_min),
        .load_enable(watch_load_en),
        .load_bcd1(set_min1), .load_bcd10(set_min10),
        .bcd1(watch_min1), .bcd10(watch_min10));
        
    loadable_counter_bcd_60 sec_set(
        .clk(clk), .reset_p(reset_p),
        .clk_time(btn_sec),
        .load_enable(set_load_en),
        .load_bcd1(watch_sec1), .load_bcd10(watch_sec10),
        .bcd1(set_sec1), .bcd10(set_sec10));
    
    loadable_counter_bcd_60 min_set(
        .clk(clk), .reset_p(reset_p),
        .clk_time(btn_min),
        .load_enable(set_load_en),
        .load_bcd1(watch_min1), .load_bcd10(watch_min10),
        .bcd1(set_min1), .bcd10(set_min10));
   
    wire [15:0] value, watch_value, set_value;    
    wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10; 
    wire [3:0] set_sec1, set_sec10, set_min1, set_min10;    
   
    assign watch_value = {watch_min10, watch_min1, watch_sec10, watch_sec1};
    assign set_value = {set_min10, set_min1, set_sec10, set_sec1}; 
    assign value = set_watch ? set_value : watch_value;   
   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule





module stop_watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output led_start, led_lap);
    
    wire clk_start;
    wire start_stop;
    reg lap;
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire btn_start, btn_lap, btn_clear;    
    wire reset_start;
    assign clk_start = start_stop ? clk : 0;

    clock_div_100 usec_clk(.clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));
    clock_div_1000 msec_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_usec), .clk_div_1000(clk_msec));
    clock_div_1000 sec_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));
    clock_div_60 min_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_sec), .clk_div_60_nedge(clk_min));
    
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));
    
    
    assign reset_start = reset_p | btn_clear;
    
    T_flip_flop_p t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
    assign led_start = start_stop;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap = 0;
        else begin
            if(btn_lap) lap = ~lap;
            else if(btn_clear) lap = 0;
        end
    end
    
    assign led_lap = lap;
    
    wire [3:0] min10, min1, sec10, sec1;   
    counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), 
        .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec1), .bcd10(sec10));
    counter_bcd_60_clear counter_min(.clk(clk), .reset_p(reset_p), 
        .clk_time(clk_min), .clear(btn_clear), .bcd1(min1), .bcd10(min10));
        
    reg [15:0] lap_time;
    wire [15:0] cur_time;
    assign cur_time = {min10, min1, sec10, sec1};
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) lap_time = 0;
        else if(btn_lap) lap_time = cur_time;
        else if(btn_clear) lap_time = 0;
    end    
        
    wire [15:0] value;    
    assign value = lap ? lap_time : cur_time;   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));    

endmodule


module stop_watch_top_homework(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output led_start, led_lap);
    
    wire clk_start;
    wire start_stop;
    reg lap;
    wire clk_usec, clk_msec, clk_sec, clk_10msec;
    wire btn_start, btn_lap, btn_clear;    
    wire reset_start;
    assign clk_start = start_stop ? clk : 0;

    clock_div_100 usec_clk(.clk(clk_start), .reset_p(reset_start), .clk_div_100(clk_usec));
    clock_div_1000 msec_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_usec), .clk_div_1000(clk_msec));
    clock_div_10 ten_msec_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_msec), .clk_div_10_nedge(clk_10msec));           
    clock_div_1000 sec_clk(.clk(clk_start), .reset_p(reset_start), 
        .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));
    
    
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));
    
    
    assign reset_start = reset_p | btn_clear;
    
    T_flip_flop_p t_start(.clk(clk), .reset_p(reset_start), .t(btn_start), .q(start_stop));
    assign led_start = start_stop;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap = 0;
        else begin
            if(btn_lap) lap = ~lap;
            else if(btn_clear) lap = 0;
        end
    end
    
    assign led_lap = lap;
    
    wire [3:0]  sec10, sec1;   
    counter_bcd_60_clear counter_sec(.clk(clk), .reset_p(reset_p), 
        .clk_time(clk_sec), .clear(btn_clear), .bcd1(sec1), .bcd10(sec10));
        
     wire [3:0]  ten_msec10, ten_msec1;   
    counter_bcd_100_clear counter_10msec(.clk(clk), .reset_p(reset_p), 
        .clk_time(clk_10msec), .clear(btn_clear), .bcd1(ten_msec1), .bcd10(ten_msec10));
    
        
    reg [15:0] lap_time;
    wire [15:0] cur_time;
    assign cur_time = { sec10, sec1, ten_msec10, ten_msec1 };
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) lap_time = 0;
        else if(btn_lap) lap_time = cur_time;
        else if(btn_clear) lap_time = 0;
    end    
        
    wire [15:0] value;    
    assign value = lap ? lap_time : cur_time;   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));    

endmodule



module cook_timer_top(
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7
//    output led_alarm, led_start,
//    output buzz
     );

    // Get 
    wire clk_usec, clk_msec, clk_sec, clk_min;
    clock_div_100 usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));

    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_usec), .clk_div_1000(clk_msec));

    clock_div_1000 sec_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec)); 

    clock_div_60 min_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_sec), .clk_div_60_nedge(clk_min));

    wire btn_start, btn_sec, btn_min, btn_alarm_off;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
    button_cntr btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_alarm_off));

    wire [3:0] set_min10, set_min1, set_sec10, set_sec1;
    wire [3:0] cur_min10, cur_min1, cur_sec10, cur_sec1;
    counter_bcd_60 counter_sec(.clk(clk), .reset_p(reset_p), 
        .clk_time(btn_sec), .bcd1(set_sec1), .bcd10(set_sec10));

    counter_bcd_60 counter_min(.clk(clk), .reset_p(reset_p), 
        .clk_time(btn_min), .bcd1(set_min1), .bcd10(set_min10));
        
    wire dec_clk;   
    loadable_down_counter_bcd_60 cur_sec(
        .clk(clk), .reset_p(reset_p), .clk_time(clk_sec),
        .load_enable(btn_start),
        .load_bcd1(set_sec1), .load_bcd10(set_sec10), 
        .bcd1(cur_sec1), .bcd10(cur_sec10), .dec_clk(dec_clk));

    loadable_down_counter_bcd_60 cur_min(
        .clk(clk), .reset_p(reset_p), .clk_time(dec_clk),
        .load_enable(btn_start),
        .load_bcd1(set_min1), .load_bcd10(set_min10), 
        .bcd1(cur_min1), .bcd10(cur_min10));

    wire [15:0] value, set_time, cur_time;
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};


    reg start_set, alarm; //기본 T플립플롭의 틀에다가 코드 추가 always문 사용 wire->reg로 변경
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            start_set = 0;
//            alarm = 0;
        end
        else begin
            if(btn_start)start_set = ~start_set;
            else if(cur_time == 0 && start_set)begin
                start_set = 0;
//                alarm = 1;
            end
//            else if(btn_alarm_off) alarm = 0;
        end
    end

//    assign led_alarm = alarm;
//    assign buzz = alarm;
//    assign led_start = start_set;

    assign value = start_set ? cur_time : set_time;
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule



// Main module
module keypad_test_top (
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [3:0] com,
    output [7:0] seg_7,
    output led_key_vaild  );
    
    // Get key_value, key_vaild
    
    // wire key_vaild;
    // assign led_key_vaild = key_vaild; 해야 하지만,
    // 이를 아래 코드 처럼 단순화 할  수 있다.
    wire [4:0] key_value;
    wire key_valid;
    key_pad_FSM keypad(.clk(clk), .reset_p(reset_p), .row(row), .col(col),  .key_value(key_value), .key_valid(key_valid) ); 
    
    // key값이 입력 되었음을 LED로 표시하기 
    assign led_key_valid = key_valid;
    
    //  One Cycle Pulse of key_valid;
    wire key_valid_p;
    edge_detector_p ed_0(.clk(clk), .reset_p(reset_p), .cp(key_valid), .p_edge(key_valid_p));
    
    // Counting key_valid
    reg [15:0] key_count;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) key_count = 0;
        else if(key_valid_p) begin
                if(key_value ==  1) key_count = key_count + 1;
                else if(key_value ==  2) key_count = key_count - 1;
                else if(key_value ==  3) key_count = key_count + 2;
        end
    end
    
    // Print FND of Key value.
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(key_count), .com(com), .seg_7(seg_7));

endmodule



module dht11_test_top (
    input clk, reset_p, 
    inout dht11_data,
    output [3:0] com,
    output [7:0] seg_7, led_debug);
    
    wire [7:0] humidity, temperature; 
    dht11_cntrl dth11( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));
    
    wire [15:0] humidity_bcd, temperature_bcd;
    bin_to_dec bcd_humi(.bin({4'b0, humidity}),  .bcd(humidity_bcd));
    bin_to_dec bcd_temp(.bin({4'b0, temperature}),  .bcd(temperature_bcd));
    
    // Print FND of Key value.
    wire [15:0] value;
    assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};  
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));
    
endmodule





module HC_SR04_top (
    input clk, reset_p, 
    input hc_sr04_echo,
    output hc_sr04_trig,
    output [3:0] com,
    output [7:0] seg_7) ;
    
    wire [21:0] distance_cm;
    HC_SR04_cntr HC_SR04_cntr_0(.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .distance(distance_cm),  .led_debug(led_debug)); 
    
    wire [11:0] distance_cm_bcd;
    bin_to_dec bcd_humi(.bin(distance_cm[11:0]),  .bcd(distance_cm_bcd));
   
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(distance_cm_bcd), .com(com), .seg_7(seg_7));    
endmodule




module led_pwm_top (
    input clk, reset_p,
    output pwm, led_r, led_g, led_b);
    
    reg [31:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
     
    pwm_100step pwm_inst(.clk(clk), .reset_p(reset_p), .duty(clk_div[27:21]), .pwm(pwm));
    
    pwm_Nstep_freq #(.duty_step(77)) pwm_r(.clk(clk), .reset_p(reset_p), .duty(clk_div[28:23]), .pwm(led_r));
    pwm_Nstep_freq #(.duty_step(93)) pwm_g(.clk(clk), .reset_p(reset_p), .duty(clk_div[27:22]), .pwm(led_g));
    pwm_Nstep_freq #(.duty_step(97)) pwm_b(.clk(clk), .reset_p(reset_p), .duty(clk_div[26:21]), .pwm(led_b));
    
endmodule



module dc_motor_pwm_top (
    input clk, reset_p,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm );
    
    // counter of Duty ratio 
    reg [31:0] clk_div;
    always @(posedge clk or posedge reset_p) begin
            if(reset_p) clk_div = 0;
            else clk_div = clk_div + 1;
    end
    
    //
     wire clk_div_26_nedge;
    edge_detector_n edge_detector_0 (.clk(clk), .reset_p(reset_p), .cp(clk_div[26]), .n_edge(clk_div_26_nedge));
    
    reg [6:0] duty; 
    always @(posedge clk or posedge reset_p) begin
            if(reset_p) duty = 20;
            else if(clk_div_26_nedge) begin
                    if(duty >= 99) duty = 20;
                    else duty = duty + 1;
            end
    end
    
    pwm_Nstep_freq #(
         .duty_step(100),
         .pwm_freq(100)) 
    pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(motor_pwm));
    
     wire [11:0] duty_bcd;
    bin_to_dec bcd_duty(.bin({10'b0, duty}),  .bcd(duty_bcd));
   
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(duty_bcd), .com(com), .seg_7(seg_7));    
endmodule



module sub_motor_pwm_top_button (
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm );

    // Get one cycle pulse of button.
    wire btn0_pedge, btn90_pedge, btn180_pedge;
    button_cntr cntr_0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn0_pedge));
    button_cntr cntr_1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn1_pedge));
    button_cntr cntr_2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn2_pedge));

    // 1.342초 마다 duty ratio 값이 증가 한다.
    reg [10:0] duty; 
    always @(posedge clk or posedge reset_p) begin
            if(reset_p) duty = 5; 
            else begin
                if(btn0_pedge) duty = 10'd5; 
                else if(btn1_pedge) duty = 10'd15; 
                else if(btn2_pedge) duty = 10'd25;
            end
    end

    // 메모장 200분주 하였다.
    // 0 ~ 10ms (5ms) : -90도 이동
    // 15ms : 0도
    // 15 ~ 20ms (25ms) : 90도 이동

    // PWM의 주파수는 50Hz이며,
    // PWM의 duty ratio를 200분주하였다,
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_motor(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(motor_pwm));

    wire [11:0] duty_bcd;
    bin_to_dec bcd_duty(.bin({10'b0, duty}),  .bcd(duty_bcd));

    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(duty_bcd), .com(com), .seg_7(seg_7));
endmodule




module surbo_motor(
    input clk, reset_p,
    output [3:0] com,
    output [7:0] seg_7,
    output surbo_pwm
);

    // system clock counter
    reg [31:0] clk_div;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            clk_div = 0;
        else
            clk_div = clk_div + 1;
    end

    // Get n_edge system clock counter
    wire clk_div_23_nedge;
    edge_detector_n ed(
        .clk(clk),
        .reset_p(reset_p),
        .cp(clk_div[23]),
        .n_edge(clk_div_23_nedge)
    );

    // 
    reg [6:0] duty;      
    reg down_up;       

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            duty = 5 ;     
            down_up = 0;  
        end
        else if (clk_div_23_nedge) begin // 20ms 주기
            if (!down_up) begin
                if (duty < 25)  
                    duty = duty + 1;
                else
                    down_up = 1;  
            end
            else begin
                if (duty > 5)  
                    duty = duty - 1;
                else
                    down_up = 0;  
            end
        end
    end

    // PWM Instance
    pwm_Nstep_freq #(
        .duty_step(200),  // 100단계로 나눔
        .pwm_freq(50)     // PWM 주파수 50Hz
    ) pwm_motor(
        .clk(clk),
        .reset_p(reset_p),
        .duty(duty),
        .pwm(surbo_pwm)
    );
    
    // Convert from binary to bcd
    wire [15:0] duty_bcd;

    bin_to_dec bcd_surbo(
        .bin({8'b0, duty}),
        .bcd(duty_bcd)
    );

    // fnd_cntr 모듈 인스턴스
    fnd_cntr fnd_cntr_inst(
        .clk(clk),
        .reset_p(reset_p),
        .value(duty_bcd),
        .com(com),
        .seg_7(seg_7)
    );

endmodule





module surbo_motor(
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output surbo_pwm
);

    wire btn_ctr0, btn_ctr1, btn_ctr2, btn_ctr3;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_ctr0)); //버튼 채터링 방지
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_ctr1)); //버튼 채터링 방지
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_ctr2)); //버튼 채터링 방지
    button_cntr btn3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pedge(btn_ctr3)); //버튼 채터링 방지

    reg [31:0] clk_div;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            clk_div = 0;
        else
            clk_div = clk_div + 1;
    end

    wire clk_div_24_nedge;

    edge_detector_n ed(
        .clk(clk),
        .reset_p(reset_p),
        .cp(clk_div[24]),
        .n_edge(clk_div_24_nedge)
    );

    reg [6:0] duty;       // duty 레지스터의 크기를 8비트로 설정
    reg direction;        // 방향 제어를 위한 플래그
    reg [6:0] duty_min, duty_max;
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            duty = 12 ;       // 초기화 1ms (5% 듀티 사이클)
            direction = 0;  // 초기 방향 설정 (0: 증가, 1: 감소)
            duty_min = 5;
            duty_max = 25;
        end
        else if (clk_div_24_nedge) begin // 20ms 주기
            if (!direction) begin
                if (duty < duty_max)  // 2ms (10%)에 도달하지 않았다면 증가
                    duty = duty + 1;
                else
                    direction = 1;  // 2ms에 도달하면 방향을 감소로 변경
            end
            else begin
                if (duty > duty_min)  // 1ms (5%)에 도달하지 않았다면 감소
                    duty = duty - 1;
                else
                    direction = 0;  // 1ms에 도달하면 방향을 증가로 변경
            end
        end
        else if(btn_ctr0)direction = ~direction;
        else if(btn_ctr1)duty_min = duty;
        else if(btn_ctr2)duty_max = duty;
    end
pwm_Nstep_freq #(
        .duty_step(400),  // 100단계로 나눔
        .pwm_freq(50)     // PWM 주파수 50Hz
    ) pwm_motor(
        .clk(clk),
        .reset_p(reset_p),
        .duty(duty),
        .pwm(surbo_pwm)
    );

    wire [15:0] duty_bcd;

    bin_to_dec bcd_surbo(
        .bin({8'b0, duty}),
        .bcd(duty_bcd)
    );

    // fnd_cntr 모듈 인스턴스
    fnd_cntr fnd_cntr_inst(
        .clk(clk),
        .reset_p(reset_p),
        .value(duty_bcd),
        .com(com),
        .seg_7(seg_7)
    );

endmodule



module adc_ch6_top (
    input clk, reset_p,
   input vauxp6, vauxn6,
   output [3:0] com,
   output [7:0] seg_7,
   output led_pwm
   );

    wire [4:0] channel_out;
    wire [16:0] do_out;
    wire eoc_out;
    
    // ADC Module instance
   xadc_wiz_0 adc_6 (
    .daddr_in({2'b0, channel_out}),
    .dclk_in(clk),
    .den_in(eoc_out),
    .reset_in(reset_p),
    .vauxp6(vauxp6),
    .vauxn6(vauxn6),
    .channel_out(channel_out),
    .do_out(do_out),
    .eoc_out(eoc_out)
);


    pwm_Nstep_freq #(
        .duty_step(256),  // 256단계로 나눔
        .pwm_freq(10000)     // PWM 주파수 10000Hz
    ) pwm_backlight(
        .clk(clk),
        .reset_p(reset_p),
        .duty(256 - do_out[15:8]),
        .pwm(led_pwm)
    );
    
    // convert from bin to dec
    wire [15:0] adc_value;
    
    bin_to_dec bcd_adc(
        .bin({2'b0, do_out[15:6]}),
        .bcd(adc_value)
    );

       // fnd_cntr 모듈 인스턴스
    fnd_cntr fnd_cntr_inst(
        .clk(clk),
        .reset_p(reset_p),
        .value(adc_value),
        .com(com),
        .seg_7(seg_7)
    );

endmodule


// 조이스틱을 통해 LED 2개 색상 제어
module adc_sequence2_top (
    input clk, reset_p,
    input vauxp6, vauxn6, vauxp15, vauxn15,
    output led_r, led_g,
    output [3:0] com,
    output [7:0] seg_7 );
    
    
    wire [4:0] channel_out;
    wire [16:0] do_out;
    wire eoc_out;
    
    // ADC Module instance
   xadc_wiz_1 adc_seq2 (
                 .daddr_in({2'b0, channel_out}),
                 .dclk_in(clk),
                 .den_in(eoc_out),
                 .reset_in(reset_p),
                 .vauxp6(vauxp6),
                 .vauxn6(vauxn6),
                 .vauxp15(vauxp15),
                 .vauxn15(vauxn15),
                 .channel_out(channel_out),
                 .do_out(do_out),
                 .eoc_out(eoc_out)
    );
    
    // Converting이 끝났는지 여부를 확인하기 위해 eoc_out 의 edge를 검출한다.
    // Convering이 끝나면 eoc_out 값이 0 -> 1로 변환
    wire eoc_out_pedge;
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    //  channel_out은 어느 채널의 do_out 값이 출력되는지를 표현한다.
    // case문을 통해 channel_out 값이 어느 채널의 do_out을 내보내는지를 확인하고, 해당 채널에 전달한다.
    // Basys3는 ADC Bit를 12bit를 갖는다.
    // ATmgae128A는 10bit, STM32도 12bit ADC Bit를 갖는다.
    reg [11:0] adc_value_x, adc_value_y;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
                adc_value_x = 0;
                adc_value_y = 0;
        end
        else if(eoc_out_pedge) begin   // eoc_out가 Positive edge가 발생하면 Converting 작업이 끝났다는 것을 의미
                case(channel_out[3:0])  // 채널 6, 15번을 사용하기 때문에 channel_out 4bit가 필요
                        6 : adc_value_x = do_out[15:4];  // ADC Data가 15bit ~ 4bit 까지 들어오고, 3bit ~ 0bit는 adc data가 아니라 다른 데이터가 들어온다.
                        15 : adc_value_y = do_out[15:4];
                endcase
        end
    end
    
    // 변환된 디지털 값으로 RED 밝기 컨트롤
    pwm_Nstep_freq #(
        .duty_step(256),  // 256단계로 나눔
        .pwm_freq(10000)     // PWM 주파수 10000Hz
    ) pwm_red(
        .clk(clk),
        .reset_p(reset_p),
        .duty(adc_value_x[11:4]),
        .pwm(led_r)
    );
    
    // 변환된 디지털 값으로 Green 밝기 컨트롤
    pwm_Nstep_freq #(
        .duty_step(256),  // 256단계로 나눔
        .pwm_freq(10000)     // PWM 주파수 10000Hz
    ) pwm_green(
        .clk(clk),
        .reset_p(reset_p),
        .duty(adc_value_y[11:4]),
        .pwm(led_g)
    );
    
    //  do_out 값을 FND로 출력해보고 확인해보기.
    // 0v ~ 1v를 6bit (64단계)로 나누어 아날로그 전압값을 디지털로 변환한다.
    // Quantization 작업
    wire [15:0] bcd_x, bcd_y, value;
    bin_to_dec bcd_adc_x( .bin({6'b0, adc_value_x[11:6]}), .bcd(bcd_x));
    bin_to_dec bcd_adc_y( .bin({6'b0, adc_value_y[11:6]}), .bcd(bcd_y));

    // bcd_x, bcd_y 값을 결합 연산자로 결합
    assign value = {bcd_x[7:0], bcd_y[7:0]};

       // fnd_cntr 모듈 인스턴스
    fnd_cntr fnd_cntr_inst(
        .clk(clk),
        .reset_p(reset_p),
        .value(value),
        .com(com),
        .seg_7(seg_7)
    );

endmodule



    