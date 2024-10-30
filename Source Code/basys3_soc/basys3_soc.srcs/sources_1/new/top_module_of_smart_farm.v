`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/23 16:16:12
// Design Name: 
// Module Name: top_module_of_smart_farm
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

// Top moudle of Smarr Farm
module top_module_of_smart_farm (
    input clk, reset_p,
    input [3:0] btn,
    input [15:0] sw,
    inout dht11_data,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    input hc_sr04_echo,
    input rx,
    output tx,
    output hc_sr04_trig,
    output left_window_pwm, right_window_pwm,
    output fan_pwm,
    output fan_dir_pwm,
    output led_pwm,
    output warning_water_level_led,
    output pump_on_off,
    output [3:0] half_step_mode_sequence,
    output scl, sda,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Button Control module
    wire btn_led_light, btn_window_mode, btn_electric_fan_power;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_led_light));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_window_mode));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_electric_fan_power));
    
    // Declare Switch
    wire sw_led_up, sw_led_down, sw_window_open, sw_window_close, sw_cntr_electirc_fan_dir, sw_electric_fan_mode;
    wire sw_led_mode, sw_led_height_mode;
    assign sw_led_height_mode = sw[0];
    assign sw_led_up = sw[1];
    assign sw_led_down = sw[2];
    assign sw_window_open = sw[6];
    assign sw_window_close = sw[7];
    assign sw_led_mode = sw[10];
    assign sw_cntr_electirc_fan_dir = sw[11];
    assign sw_electric_fan_mode = sw[15];
    
    // Declare sensor variables.
    wire [15:0] dht11_value;
    wire [7:0] sunlight_value;
    wire water_flag;
    wire led_up_down;
    wire [21:0] distance_cm;
    
    // Instance of sensor module
    dht11_control dht11_control_instance (.clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .dht11_value(dht11_value));
    cds_and_water_level_control cds_and_water_level_control_instance (.clk(clk), .reset_p(reset_p), .vauxp6(vauxp6), .vauxn6(vauxn6), .vauxp15(vauxp15), .vauxn15(vauxn15), .water_flag(water_flag), .sunlight_value(sunlight_value) );
    HC_SR04_cntr HC_SR04_cntr_0(.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .distance(distance_cm),  .led_debug(led_debug)); 
    
    // Instance of Control module
    window_control window_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sw_window_open(sw_window_open), .sw_window_close(sw_window_close), .btn_window_control(btn_window_mode), .left_window_pwm(left_window_pwm), .right_window_pwm(right_window_pwm));
    electric_fan_control electric_fan_control_instance (.clk(clk), .reset_p(reset_p), .sw_cntr_electirc_fan_dir(sw_cntr_electirc_fan_dir), .sw_electric_fan_mode(sw_electric_fan_mode), .dht11_value(dht11_value), .btn_electric_fan_power(btn_electric_fan_power), .fan_pwm(fan_pwm), .fan_dir_pwm(fan_dir_pwm));
    led_control led_control_instance (.clk(clk), .reset_p(reset_p), .sw_led_mode(sw_led_mode), .btn_led_light(btn_led_light), .water_flag(water_flag), .sunlight_value(sunlight_value), .led_pwm(led_pwm), .warning_water_level_led(warning_water_level_led));
    water_pump water_pump_instance (.clk(clk), .reset_p(reset_p), .water_flag(water_flag), .pump_on_off(pump_on_off));  
    led_height_control led_height_control_instance ( .clk(clk), .reset_p(reset_p), .sw_led_height_mode(sw_led_height_mode), .distance_cm(distance_cm),
                        .sw_led_up(sw_led_up), .sw_led_down(sw_led_down), .half_step_mode_sequence(half_step_mode_sequence));
    
    // Instance of a module that displays temperature and humidity information      
    lcd_display_control lcd_display_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sunlight_value(sunlight_value), .water_flag(water_flag), .scl(scl), .sda(sda));
    uart_app_control uart_app_control_instance (.clk(clk), .reset_p(reset_p), .rx(rx), .dht11_value(dht11_value), .tx(tx));
    
    // Show temperature, humidity to FND
    show_the_fnd show_the_fnd_instance(.clk(clk), .reset_p(reset_p), .hex_value(dht11_value), .sunlight_value(sunlight_value), .com(com), .seg_7(seg_7), .distance_cm(distance_cm));
    
    
endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////////////////////////        temp Module        ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module show_the_fnd (
    input clk, reset_p,
    input [15:0] hex_value,
    input [7:0] sunlight_value,
    input [21:0] distance_cm,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Convert from binary to BCD Code
    wire [11:0] temperature_bcd, humidity_bcd;
    bin_to_dec bcd_temp(.bin({4'b0, hex_value[15:8]}),  .bcd(temperature_bcd));
    bin_to_dec bcd_humi(.bin({4'b0, hex_value[7:0]}),  .bcd(humidity_bcd));
    
    // FND Control module
    fnd_cntr fnd_cntr_instance (.clk(clk), .reset_p(reset_p), .value({temperature_bcd[7:0], humidity_bcd[7:0]}), .com(com), .seg_7(seg_7));
    
endmodule


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////        Senseor Module        ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


// hc_sr04_control 
module hc_sr04_control (
    input clk, reset_p, 
    input hc_sr04_echo,
    output hc_sr04_trig,
    output [7:0] distance_between_plant_and_led );
    
    // Instance of HC_SR04 Control module
    HC_SR04_cntr HC_SR04_cntr_1 (.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .distance(distance_between_plant_and_led)); 
endmodule




// DHT11 Control module
module dht11_control(
    input clk, reset_p, 
    inout dht11_data,
    output [15:0] dht11_value);

    wire [7:0] humidity, temperature; 
    dht11_cntrl dth11( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));

    assign dht11_value = {temperature[7:0], humidity[7:0]};

endmodule



// cds_and_water_level_control module
module cds_and_water_level_control (
    input clk, reset_p,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    output reg water_flag,
    output reg [7:0] sunlight_value );
    
     wire [4:0] channel_out;
     wire [16:0] do_out;
     wire eoc_out;

     // ADC Module instance
       xadc_wiz_10 xadc_cds (
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
    
    // Get positive edge of eoc_out.
    wire eoc_out_pedge;
    edge_detector_p ed_eoc_out_cds(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    // Channel_out 변수 값에 따라 변환된 Channel이 무엇인지를 확인 후, 해당 값을 출력
    // do_out 값이 100미만 이면 물이 부족한 상태 ----> 1
    // do_out 값이 100이상 이면 물이 충분한 상태 ----> 0  
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            sunlight_value = 0;
            water_flag = 0;
        end
        else if(eoc_out_pedge) begin
            case(channel_out[3:0])
                6 : begin sunlight_value = do_out[15:8]; end
                15 : begin water_flag  = (do_out[15:9]<100) ? 1 : 0; end
            endcase
        end
    end
     
endmodule

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////        Control Module        ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////



// Window control module
module window_control (
    input clk, reset_p,
    input [15:0] dht11_value,
    input sw_window_open,
    input sw_window_close,
    input btn_window_control,
    output left_window_pwm, right_window_pwm);
    
    // Declare temperature, humidity 
    wire [7:0] temperature, humidity;
    assign temperature = dht11_value [15:8];
    assign humidity = dht11_value [7:0];
    
    // Declare state machine.
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'b10;
    
    // Declare state, next state variables
    reg [1:0] state, next_state;
    
    // 언제 다음 상태 단계로 전이되는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_MANUAL_MODE;
        else if(btn_window_control) state = next_state;
    end
    
    // Declare duty of window
    // right_min_duty == Window Open, right_max_duty == Window Close
    // left_min_duty == Window Close, left_max_duty == Window Open
    reg [5:0] left_duty, right_duty;
    reg [5:0] right_min_duty, right_max_duty;
    reg [5:0] left_min_duty, left_max_duty;

    // 1msec Clock Pulse
    wire clk_usec, clk_msec;
    clock_div_100 usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), 
        .clk_source(clk_usec), .clk_div_1000(clk_msec));
    
    // 각 상태 단계의 동작 및 다음 상태 전이 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
           next_state =  S_MANUAL_MODE;
           right_duty = right_max_duty;
           left_duty = left_min_duty;
              
           right_max_duty = 6'd18;
           right_min_duty = 6'd5;
           
           left_max_duty = 6'd25;
           left_min_duty = 6'd11;
        end
        else if(clk_msec) begin
            case (state) 
                // 1단계) 수동 조작 단계
                S_MANUAL_MODE: begin
                    if(sw_window_open) begin
                        if(right_duty > right_min_duty) right_duty = right_duty - 1;
                        if(left_duty < left_max_duty) left_duty = left_duty + 1;
                    end
                    else if(sw_window_close) begin
                        if(right_duty < right_max_duty) right_duty = right_duty + 1;
                        if(left_duty > left_min_duty) left_duty = left_duty - 1;
                    end 
                    
                    next_state = S_AUTO_MODE;        
                end
                
                // 2단계) 자동 조작 단계
                 S_AUTO_MODE : begin
                    if(temperature < 8'd27) begin
                        right_duty = right_max_duty;
                        left_duty = left_min_duty;
                    end
                    else begin 
                        right_duty = right_min_duty;
                        left_duty = left_max_duty;
                    end
                    
                    next_state = S_MANUAL_MODE;
                 end   
            endcase 
        end
    end
    
    // Instance of pwm_control module
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_right_servo_motor (.clk(clk), .reset_p(reset_p), .duty(right_duty), .pwm(right_window_pwm));
    
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_left_servo_motor (.clk(clk), .reset_p(reset_p), .duty(left_duty), .pwm(left_window_pwm));
    
endmodule



// Electric Fan Control
module electric_fan_control (
    input clk, reset_p,
    input sw_cntr_electirc_fan_dir,
    input sw_electric_fan_mode,
    input btn_electric_fan_power,
    input [15:0] dht11_value,
    output fan_pwm, fan_dir_pwm );
    
    // Declare state machine
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'b10;
    
    // Declare state, next state
    reg [1:0] power_state;
    
    // 언제 다음 상태로 넘어가는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) power_state = S_MANUAL_MODE; 
        else if(sw_electric_fan_mode) power_state = S_AUTO_MODE;
        else if(!sw_electric_fan_mode) power_state = S_MANUAL_MODE;
    end
    
    // Register duty of electirc fan.
    reg [1:0] fan_manual_duty, fan_auto_duty;   
    
    
    // Declare temperature, humidity 
    wire [7:0] temperature, humidity;
    assign temperature = dht11_value [15:8];
    assign humidity = dht11_value [7:0];
    
    // 각 상태의 동작 및 다음 상태 단계로 전이되기 위한 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            fan_manual_duty = 0;
            fan_auto_duty = 0;
        end
        else begin
            case(power_state)
                S_MANUAL_MODE : begin
                    if(btn_electric_fan_power) begin
                        if(fan_manual_duty >= 3) fan_manual_duty = 0;
                        else fan_manual_duty = fan_manual_duty + 1;
                    end
                end
                
                S_AUTO_MODE : begin
                    if(temperature < 27) fan_auto_duty = 0;
                    else if(27 <= temperature && temperature < 29) fan_auto_duty = 1;
                    else if(29 <= temperature && temperature <= 31) fan_auto_duty = 2;
                    else if(temperature > 31) fan_auto_duty = 3;
                end
           endcase        
        end
    end
    
    // Select duty of electric fan
    wire [1:0] duty;
    assign duty = (power_state == S_MANUAL_MODE) ? fan_manual_duty : fan_auto_duty;
    
    // Get pwm of electric fan
    pwm_cntr #(.pwm_freq(100), .duty_step(4)) control_power_pwm (.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(fan_pwm));
  
    
    
    
    // Declare State Machine
    parameter S_SERVO_STOP = 2'b01;
    parameter S_SERVO_START = 2'b10;
    
    // Declcare state variable
    reg [1:0] dir_state;
    
    // clock divider 1sec
    wire clk_1usec, clk_1msec, clk_1sec;
    clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_1usec)); 
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1usec), .clk_div_1000_nedge(clk_1msec));
    clock_div_1000 sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1msec), .clk_div_1000_nedge(clk_1sec));
    
    // Declare necessary variables
    reg [4:0] dir_duty;
    reg [4:0] dir_min_duty;
    reg [4:0] dir_max_duty;
    reg direction_of_fan; // direction_of_fan == 0 이면 감소, direction_of_fan == 1 이면 증가
    
    // 언제 다음 state로 전이되는가>
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) dir_state = S_SERVO_STOP;
        else if(sw_cntr_electirc_fan_dir) dir_state = S_SERVO_START;
        else if(!sw_cntr_electirc_fan_dir) dir_state = S_SERVO_STOP;
    end
  
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            dir_min_duty = 5'd8;
            dir_max_duty = 5'd22;
            dir_duty = 5'd15;
            direction_of_fan = 0;
        end
        else if(clk_1sec) begin
            case(dir_state)
                S_SERVO_STOP : begin
                    dir_duty = dir_duty;
                end
            
                S_SERVO_START : begin
                    if(direction_of_fan) begin
                        if(dir_duty == dir_max_duty) begin
                            dir_duty = dir_duty - 1;
                            direction_of_fan = ~ direction_of_fan;
                        end
                        else dir_duty = dir_duty + 1;
                    end
                    else begin
                        if(dir_duty == dir_min_duty) begin
                            dir_duty = dir_duty + 1;
                            direction_of_fan = ~ direction_of_fan;
                        end
                        else dir_duty = dir_duty - 1;
                    end
                end
            endcase
        end
    end
  
    // Get pwm of servo-motor
    pwm_cntr #(.pwm_freq(50), .duty_step(200)) control_servo_pwm (.clk(clk), .reset_p(reset_p), .duty(dir_duty), .pwm(fan_dir_pwm));

endmodule




// LED Control module
module led_control (
    input clk, reset_p,
    input sw_led_mode,
    input btn_led_light,
    input water_flag,
    input [7:0] sunlight_value,
    output led_pwm, warning_water_level_led );
    
    // Warning Water Level LED
    assign warning_water_level_led = water_flag;
    
    // Main LED Control
    // Declare state machine
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'B10;
    
    // Declare state variable
    reg [1:0] state;
    
    // Declare duty variabels
    wire [2:0] led_duty;
    reg [2:0] manual_duty;
    reg [7:0] auto_duty;
    wire manual_pwm, auto_pwm;
    
    // 언제 다음 상태로 전이되는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_MANUAL_MODE;
        else if(sw_led_mode) state = S_AUTO_MODE;
        else if(!sw_led_mode) state = S_MANUAL_MODE;
    end
    
    // 각 상태에 대한 행동 및 다음 상태로 전이되기 위한 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            manual_duty = 0;
            auto_duty = 0;
        end
        else begin
            case(state) 
                S_MANUAL_MODE : begin
                    if(btn_led_light) begin
                        if(manual_duty >= 5) manual_duty = 0;
                        else manual_duty = manual_duty + 1;
                    end
                end
                
                S_AUTO_MODE : begin
                   auto_duty = 256 - sunlight_value;
                   
                   if(auto_duty <= 50) auto_duty = 0;
                end
            endcase
        end
    end
    
    // Instance of pwm control
    pwm_cntr #(.pwm_freq(10_000), .duty_step(6)) control_manual_led_pwm (.clk(clk), .reset_p(reset_p), .duty(manual_duty), .pwm(manual_pwm));
    pwm_cntr #(.pwm_freq(10_000), .duty_step(256)) control_auto_led_pwm (.clk(clk), .reset_p(reset_p), .duty(auto_duty), .pwm(auto_pwm));
    
    // Select led pwm
    assign led_pwm = (state == S_MANUAL_MODE) ? manual_pwm : auto_pwm;
    
endmodule

// LED Height Control module
module led_height_control(
    input clk, reset_p,
    input sw_led_height_mode,
    input [21:0] distance_cm,
    input sw_led_up, sw_led_down,
    output [3:0] half_step_mode_sequence);
    
    // Declare state machine 
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'b10;
    
    // Declare state variable
    reg [1:0] state;
    
    // 언제 다음 state로 전이되는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_MANUAL_MODE;
        else if(sw_led_height_mode) state = S_AUTO_MODE;
        else if(!sw_led_height_mode) state = S_MANUAL_MODE;
    end
    
    // Declare necessary variables
    reg up_down, motor_enable;
    
    // 각 상태 단계에서의 동작 및 다음 상태 전이 조건
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            up_down = 1;
            motor_enable = 0;
        end
        else begin
            case(state) 
                S_MANUAL_MODE :begin
                    if(sw_led_up) begin
                        up_down = 1;
                        if(sw_led_down) motor_enable = 0;
                        else motor_enable = 1;
                    end
                    else if(sw_led_down) begin
                        up_down = 0;
                        if(sw_led_up) motor_enable = 0;
                        else motor_enable = 1;
                    end
                    else motor_enable = 0;
                end
                
                S_AUTO_MODE : begin
                    if(distance_cm < 22'd7) begin
                        up_down = 1;
                        motor_enable = 1; 
                    end
                    else if(distance_cm > 22'd15) begin
                        up_down = 0;
                        motor_enable = 1;
                    end
                    else motor_enable = 0;                    
                end
            endcase
        end
    end
    
    // Instance of Step motor control module
    step_motor_control step_motor_control_instance (.clk(clk), .reset_p(reset_p), .up_down(up_down), .motor_enable(motor_enable), .half_step_mode_sequence(half_step_mode_sequence));
endmodule


// Step Motor Control Module
module step_motor_control (
    input clk, reset_p,
    input up_down,
    input motor_enable,
    output reg [3:0] half_step_mode_sequence );
    
    // 1msec clk
    wire clk_1usec, clk_1mssec;
    clock_div_100 usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_1usec));
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1usec), .clk_div_1000_nedge(clk_1mssec));
    
    // msecond counter
    reg [1:0] counter;
    reg counter_enable;
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) counter = 0;
        else if(clk_1mssec && counter_enable) counter = counter + 1;
        else if(!counter_enable) counter = 0;       
    end
    
    // Control step motor
    // Half step 시퀀스
    wire [3:0] half_step_sequence [0:7];
    assign half_step_sequence[0] = 4'b1001; // 0x9
    assign half_step_sequence[1] = 4'b0001; // 0x1
    assign half_step_sequence[2] = 4'b0011; // 0x3
    assign half_step_sequence[3] = 4'b0010; // 0x2
    assign half_step_sequence[4] = 4'b0110; // 0x6
    assign half_step_sequence[5] = 4'b0100; // 0x4
    assign half_step_sequence[6] = 4'b1100; // 0xC
    assign half_step_sequence[7] = 4'b1000; // 0x8
    
    // Declare State Machine
    parameter S_SEND_SEQUENCE = 2'b01;
    parameter S_WAIT_1MS = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 언제 다음 state로 전이되는가?
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) state = S_SEND_SEQUENCE;
        else state = next_state;
    end
    
    // Delcare Data count
    reg [2:0] reg_cnt_data;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            counter_enable = 0; 
            reg_cnt_data = 0;
            next_state = S_SEND_SEQUENCE;
        end
        else begin
            if(motor_enable) begin
                case (state)
                    S_SEND_SEQUENCE : begin
                        case(up_down) 
                            1 : begin
                                half_step_mode_sequence = half_step_sequence[reg_cnt_data];
                                reg_cnt_data = reg_cnt_data + 1;
                            end
                    
                            0 : begin
                                half_step_mode_sequence = half_step_sequence[reg_cnt_data];
                                reg_cnt_data = reg_cnt_data - 1;
                            end 
                        endcase
                        
                        next_state = S_WAIT_1MS;
                    end
                    
                    S_WAIT_1MS : begin
                        if(counter < 2'd1) 
                            counter_enable = 1;
                        else begin
                            counter_enable = 0;
                            next_state = S_SEND_SEQUENCE;
                        end
                    end   
                endcase
            end
        end
    end
    
endmodule


// Water Pump Control module
module water_pump (
    input clk, reset_p,
    input water_flag,
    output pump_on_off );
    
    assign pump_on_off = water_flag;
    
endmodule