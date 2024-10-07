`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/26 12:28:38
// Design Name: 
// Module Name: i2c_lcd_send_byte
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

module lcd_display_control (
    input clk, reset_p,
    input [15:0] dht11_value,
    input [7:0] sunlight_value,
    input water_flag,
    output scl, sda);
    
    // Convert from binary to BCD
    wire [7:0] temperature, humidity;
    wire [15:0] temperature_bcd, humidity_bcd;
    
    assign temperature = dht11_value[15:8];
    assign humidity = dht11_value[7:0];
    
    bin_to_dec bcd_temp(.bin({4'b0, temperature}),  .bcd(temperature_bcd));
    bin_to_dec bcd_humi(.bin({4'b0, humidity}),  .bcd(humidity_bcd));
    
    // Declare state machine
    parameter IDLE = 9'b0_0000_0001;
    parameter INIT = 9'b0_0000_0010;
    parameter SEND_STRING_TEMPERATURE = 9'b0_0000_0100;
    parameter SEND_TEMPERATURE_DATA = 9'b0_0000_1000;
    parameter SEND_COMMAND_NEXT_LINE = 9'b0_0001_0000;
    parameter SEND_STRING_HUMIDITY = 9'b0_0010_0000;
    parameter SEND_HUMIDITY_DATA = 9'b0_0100_0000;
    parameter WAIT_1SEC = 9'b0_1000_0000;
    parameter SEND_COMMAND = 9'b1_0000_0000;

      // Get usecond clock
      wire clk_usec;
      clock_div_100 usec_clk (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));
        
      // 마이크로세컨드 단위로 카운트 
      // enable 이 1이면 카운트 동작 , 1이 아니면 0으로 카운트 초기화 
      reg [21:0] count_usec;
      reg count_usec_en;
      always @(negedge clk or posedge reset_p)begin
             if(reset_p) count_usec = 0;
             else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
             else if(!count_usec_en) count_usec = 0;
        end
        
        // Declare register of text
        reg [7:0] send_buffer;
        
        // Declare varables
        reg rs, send;
        wire busy;
        
        //  instance of i2c lcd send byte 
        i2c_lcd_send_byte i2c_lcd_send_byte_0 (.clk(clk), .reset_p(reset_p),
                                        .addr(7'h27), .send_buffer(send_buffer), .rs(rs), .send(send),             
                                        .scl(scl), .sda(sda), .busy(busy));                                   
                                        
        // Declare state, next state
        reg [10:0] state, next_state;
        
        // 언제 다음 상태로 넘어가는가?
        always @(negedge clk or posedge reset_p) begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
    
        // 초기화 했는지 여부를 나타내는 FLAG Register
        reg init_flag, flag_reset;
        
        // Counting for data
        reg [9:0] cnt_data ;
        
        // 문자열 Register
        reg [14*8-1:0] str_temperature;
        reg [11*8-1:0] str_humidity;
        reg [9:0] cnt_string;
        
        // 각 상태에 대한 동작 정의
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                    next_state = IDLE;
                    init_flag = 0;
                    count_usec_en = 0;
                    cnt_data = 0;
                    rs = 0;
                    str_temperature = "Temperature : "; // C언어처럼 마지막에 NULL은 없다.
                    str_humidity = "Humidity : ";
                    cnt_string = 0;
                    flag_reset = 0;
                end
                else begin
                    case (state)
                            // 1단계) IDLE
                            IDLE : begin
                                    if(init_flag) begin
                                        if(count_usec < 22'd1000) begin
                                                count_usec_en = 1;
                                        end
                                        else begin
                                            count_usec_en = 0;
                                            next_state = SEND_STRING_TEMPERATURE;          
                                        end
                                    end
                                    else  begin
                                            if(count_usec <= 22'd80_000) begin
                                                count_usec_en = 1;
                                            end
                                            else begin
                                                count_usec_en = 0;
                                                next_state = INIT;
                                             end
                                    end
                            end
                            
                            // 2단계) INIT
                            INIT : begin
                                if(busy) begin
                                     send = 0;
                                     
                                     if(cnt_data >=6) begin                   
                                        init_flag = 1;
                                        cnt_data = 0;
                                        next_state = IDLE;       
                                     end
                                end
                                else if(!send) begin // send == 0 && busy == 0일 때만 동작
                                                     // busy는 다음 posedge 일 때 0-> 1로 변화하기 때문에
                                                     // 8'h33을 보내고, 바로 8'h82로 보내서 위와 같은 조건을 추가
                                        case(cnt_data)
                                                0: send_buffer = 8'h33;
                                                1: send_buffer = 8'h32;
                                                2: send_buffer = 8'h2a; // 2줄, 5X8 Dots 사용
                                                3: send_buffer = 8'h0c; // Display : 1, Cursor : on + 깜빡임 
                                                4: send_buffer = 8'h01;
                                                5: send_buffer = 8'h06; 
                                        endcase 
                                        
                                        rs = 0;
                                        cnt_data = cnt_data + 1;
                                        send = 1;
                                end
                            end
                            
                            // 3단계) SEND_STRING_TEMPERATURE
                            SEND_STRING_TEMPERATURE : begin
                                if(busy) begin
                                     send = 0;
                                     
                                     if(cnt_string >= 14) begin                   
                                        cnt_string = 0;
                                        next_state = SEND_TEMPERATURE_DATA;       
                                     end
                                end
                                else if(!send) begin // send == 0 && busy == 0일 때만 동작
                                                     // busy는 다음 posedge 일 때 0-> 1로 변화하기 때문에
                                                     // 8'h33을 보내고, 바로 8'h82로 보내서 위와 같은 조건을 추가
                                        case(cnt_string)
                                                0: send_buffer = str_temperature[111 : 104];
                                                1: send_buffer = str_temperature[103 : 96];
                                                2: send_buffer = str_temperature[95 : 88];
                                                3: send_buffer = str_temperature[87 : 80];
                                                4: send_buffer = str_temperature[79 : 72];
                                                5: send_buffer = str_temperature[71 : 64];
                                                6: send_buffer = str_temperature[63 : 56];
                                                7: send_buffer = str_temperature[55 : 48];
                                                8: send_buffer = str_temperature[47 : 40];
                                                9: send_buffer = str_temperature[39 : 32];
                                                10: send_buffer = str_temperature[31 : 24];
                                                11: send_buffer = str_temperature[23 : 16];
                                                12: send_buffer = str_temperature[15 : 8];
                                                13: send_buffer = str_temperature[7 : 0];
                                        endcase 
                                        
                                        rs = 1;
                                        cnt_string = cnt_string + 1;
                                        send = 1;
                                end
                          end
                            
                            
                            // 4단계) SEND_TEMPERATURE_DATA
                            SEND_TEMPERATURE_DATA : begin
                                    if(busy) begin
                                            send = 0;
        
                                            if(cnt_data >= 2) begin 
                                                    cnt_data = 0;
                                                    next_state = SEND_COMMAND_NEXT_LINE;
                                            end
                                    end
                                    else if(!send) begin
                                        case(cnt_data) 
                                            0 : send_buffer = "0" + temperature_bcd[7:4];
                                            1 : send_buffer = "0" + temperature_bcd[3:0];
                                        endcase
                                        
                                        cnt_data = cnt_data + 1;
                                        rs = 1;
                                        send = 1;
                                    end
                            end
                            
                            // 5단계) SEND_COMMAND_NEXT_LINE
                            SEND_COMMAND_NEXT_LINE : begin
                                    if(busy) begin
                                            if(flag_reset) begin
                                                flag_reset = 0;
                                                next_state = SEND_STRING_HUMIDITY;
                                            end
                                            send = 0;
                                  end
                                  else begin
                                            send_buffer = 8'hc0;
                                            rs = 0;
                                            send = 1;
                                            flag_reset = 1;
                                 end
                            end
                            
                            
                            // 6단계) SEND_STRING_HUMIDITY
                            SEND_STRING_HUMIDITY : begin
                                if(busy) begin
                                     send = 0;
                                     
                                     if(cnt_string >= 11) begin                   
                                        cnt_string = 0;
                                        next_state = SEND_HUMIDITY_DATA;       
                                     end
                                end
                                else if(!send) begin // send == 0 && busy == 0일 때만 동작
                                                     // busy는 다음 posedge 일 때 0-> 1로 변화하기 때문에
                                                     // 8'h33을 보내고, 바로 8'h82로 보내서 위와 같은 조건을 추가
                                        case(cnt_string)
                                                0: send_buffer = str_humidity[87 : 80];
                                                1: send_buffer = str_humidity[79 : 72];
                                                2: send_buffer = str_humidity[71 : 64];
                                                3: send_buffer = str_humidity[63 : 56];
                                                4: send_buffer = str_humidity[55 : 48];
                                                5: send_buffer = str_humidity[47 : 40];
                                                6: send_buffer = str_humidity[39 : 32];
                                                7: send_buffer = str_humidity[31 : 24];
                                                8: send_buffer = str_humidity[23 : 16];
                                                9: send_buffer = str_humidity[15 : 8];
                                                10: send_buffer = str_humidity[7 : 0];
                                        endcase 
                                        
                                        rs = 1;
                                        cnt_string = cnt_string + 1;
                                        send = 1;
                                end
                          end
                          
                  
                          // 7단계) SEND_HUMIDITY_DATA
                          SEND_HUMIDITY_DATA : begin
                                if(busy) begin
                                            send = 0;
                                            
                                            if(cnt_data >= 2) begin
                                                cnt_data = 0;       
                                                next_state = WAIT_1SEC;
                                             end
                                    end
                                    else if(!send) begin
                                            case(cnt_data) 
                                                0 : send_buffer = "0" + humidity_bcd[7:4];
                                                1 : send_buffer = "0" + humidity_bcd[3:0];
                                            endcase
                                            
                                            cnt_data = cnt_data + 1;
                                            rs = 1;
                                            send = 1;
                                    end
                          end
                          
                          // 8단계) WAIT_1SEC
                          WAIT_1SEC : begin
                                if(count_usec < 22'd1_000_000) begin
                                     count_usec_en = 1;
                                end
                                else begin
                                       count_usec_en = 0;
                                       next_state = SEND_COMMAND;
                                end
                          end
                          
                          // 9단계) SEND_COMMAND
                          SEND_COMMAND : begin
                                 if(busy) begin
                                       send = 0;
                                  end 
                                  else if(!send) begin
                                            if(flag_reset) begin
                                                flag_reset = 0;
                                                next_state = IDLE;
                                            end
                                            else begin
                                                send_buffer = 8'h01;
                                                rs = 0;
                                                send = 1;
                                                flag_reset = 1;
                                            end     
                                 end
                          end
                    endcase
                end
                
        end
        
endmodule

// LCD 디스플레이와 i2c 통신 
// 1 byte 단위 데이터 전송
module i2c_lcd_send_byte (
        input clk, reset_p,
        input [6:0] addr,
        input [7:0] send_buffer,
        input rs, send,               // 
        output scl, sda,
        output reg busy,
        output [15:0] led );        // Register가 LCD로 데이터를 보내는 동안에는 
                                    // 외부에서 데이터 보내는 중인 상태임을 표시하기 위해
                                    // busy == 1 이면 데이터 전송중인 상태, busy == 0이면 데이터 전송 중이 아닌 상태


        // Decalare State Machine
        parameter IDLE                            = 6'b00_0001;
        parameter SEND_HIGH_NIBBLE_DISABLE        = 6'b00_0010;
        parameter SEND_HIGH_NIBBLE_ENABLE         = 6'b00_0100;
        parameter SEND_LOW_NIBBLE_DISABLE         = 6'b00_1000;
        parameter SEND_LOW_NIBBLE_ENABLE          = 6'b01_0000;
        parameter SEND_DISABLE                    = 6'b10_0000;


        // Declare variables.
        reg [7:0] data;
        reg comm_go;
        
        //  Get positive edge of send
        wire send_pedge;
        edge_detector_n comm_go_edge (.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
        
        // Get usecond clock
        wire clk_usec;
        clock_div_100 usec_clk (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));
        
        // 마이크로세컨드 단위로 카운트 
        // enable 이 1이면 카운트 동작 , 1이 아니면 0으로 카운트 초기화 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        // Declare state, next state variable
        reg [5:0] state, next_state;
        
        // 언제 다음 상태로 넘어가는가?
        always @(negedge clk or posedge reset_p) begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                        next_state = IDLE;
                        busy = 0;
                        comm_go = 0;
                        count_usec_en = 0;
                        data = 0; 
                end
                else begin
                        case(state)
                                // 1단계) IDLE
                                IDLE : begin
                                        if(send_pedge) begin 
                                                next_state = SEND_HIGH_NIBBLE_DISABLE;
                                                busy = 1;   
                                        end
                                end  
                                
                                // 2단계) SEND_HIGH_NIBBLE_DISABLE
                                SEND_HIGH_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // 데이터 전송
                                                data = {send_buffer[7:4], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_HIGH_NIBBLE_ENABLE;
                                        end
                                end 
                                
                                // 3단계) SEND_HIGH_NIBBLE_ENABLE
                                SEND_HIGH_NIBBLE_ENABLE : begin
                                         if(count_usec <= 22'd200) begin
                                                // 데이터 전송
                                                data = {send_buffer[7:4], 3'b110, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_LOW_NIBBLE_DISABLE;
                                        end
                                end 
                                
                                // 4단계) SEND_LOW_NIBBLE_DISABLE
                                SEND_LOW_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // 데이터 전송
                                                data = {send_buffer[3:0], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_LOW_NIBBLE_ENABLE;
                                        end
                                end     
                                
                                // 5단계) SEND_LOW_NIBBLE_ENABLE
                                SEND_LOW_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // 데이터 전송
                                                data = {send_buffer[3:0], 3'b110, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_DISABLE;
                                        end
                                end 
                                
                                // 6단계) SEND_DISABLE
                                SEND_DISABLE : begin
                                         if(count_usec <= 22'd200) begin
                                                // 데이터 전송
                                                data = {send_buffer[3:0], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = IDLE;
                                                busy = 0;
                                        end
                                end 
                        endcase
                end
        end

        // Instance of I2C master module
        I2C_master I2C_master_0 (.clk(clk), .reset_p(reset_p), .addr(addr),  .rd_wr(0), .data(data),  .comm_go(comm_go), .scl(scl), .sda(sda), .led(led));
        
endmodule  


// I2C_master
// i2c 통신
module I2C_master (
    input clk, reset_p,
    input [6:0] addr, // Slave의 주소는 7bit이다.
    input rd_wr,       // 데이터를 read할것인지 write할 것인지
    input [7:0] data,  // Slave쪽으로 보낼 데이터의 크기는 8bit
    input comm_go,  // comm_go 변수는 전체 통신을 시작을 enable시켜주는 변수
    output reg scl, sda,
    output reg [15:0] led );
    
    // 7개의 state로 정의
    // 블로그 게시글 참고
    parameter IDLE = 7'b000_0001;
    parameter COMM_START = 7'b000_0010;
    parameter SEND_ADDR = 7'b000_0100;
    parameter RD_ACK = 7'b000_1000;
    parameter SEND_DATA = 7'b001_0000;
    parameter SCL_STOP = 7'b010_0000;
    parameter COMM_STOP = 7'b100_0000;
    
    
    //  Slave 주소 + Master 쪽에서 Read할것인지 Write할것인지를 담고 있는 8bit wire
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};
    
    // I2C 통신에서 사용하는 Clock signal은 일반적으로 100kHz를 사용 == 10us period 인 Clock Pulse 생성
    // Master에서 Clock Speed을 정해준다.
    // I2C 통신의 Clock Speed는 정해진 속도 없이 Master에 의해 결정된다.
    // 이번 구현에서는 Clock Speed는 100kHz 주파수를 갖는다.
    wire clk_usec;
    clock_div_100 usec_clk (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));
    
    
    // usec one cycle pulse을 통해 5초 카운트하고, Toggle하는 형식으로 
    // 주기각 10usec인 Clock Pulse를 만든다.
    reg [2:0] counter_usec5; // 10us 주기인 Clock Pulse를 만들기 위한 Register
    reg scl_e;  // scl 신호선의 enable
    
    // 10usec 주기인 Clock Pulse를 만들기
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)  begin
             counter_usec5 = 0;   
             scl = 1;   // IDLE 상태에서는 High-level이다.
        end
        else if(scl_e) begin
                if(clk_usec) begin
                    if(counter_usec5 >= 4) begin
                        counter_usec5 = 0;
                        scl = ~scl;              // SCL 신호선의 값을 Toggle시킨다.
                     end
                    else  counter_usec5 = counter_usec5 + 1;
                end 
        end
        else if(!scl_e) begin
                scl = 1;   // SCL 신호선이 Disable이면 1로 초기화
                counter_usec5 = 0;   
        end
    end 
    
    
    // Get edge of 10usec인 Clock Pulse 
    // Clock Signal edge에 맞춰서 데이터를 수정할 것이기 때문에 edge가 필요하다.
    wire scl_nedge, scl_pedge;
    edge_detector_n scl_edge (.clk(clk), .reset_p(reset_p), .cp(scl), .p_edge(scl_pedge), .n_edge(scl_nedge));
    
    //  Get positive edge of Comm-go
    wire comm_go_pedge;
    edge_detector_n comm_go_edge (.clk(clk), .reset_p(reset_p), .cp(comm_go), .p_edge(comm_go_pedge));
    
    // state와 next state 변수 선언
    reg [6:0] state, next_state;
    
    // 언제 다음 상태로 넘어가는가?
    always @(negedge clk or posedge reset_p) begin
         if(reset_p) state = IDLE;
         else state = next_state;
    end
    
    
    // 8bit 데이터를 순차적으로 보내기 위한 register
    reg [2:0] cnt_bit;
    
    // 
    reg stop_flag;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state = IDLE;
            scl_e = 0;
            sda = 1;
            cnt_bit = 7;
            stop_flag = 0;
        end
        else begin
            case(state)
                 // 1단계 : IDLE
                 IDLE : begin
                        scl_e = 0;       // SCL Disable 상태
                        sda = 1;        // SDA 신호선은 1로 유지
                        
                        if(comm_go_pedge) next_state = COMM_START;
                 end
                 
                 // 2단계 : COMM_START
                 COMM_START : begin
                       sda = 0;        // Start Start Signal 
                       scl_e = 1;       // SCL able 상태
                       
                       next_state = SEND_ADDR;
                 end
                 
                 // 3단계 : SEND_ADDR
                 SEND_ADDR : begin
                        if(scl_nedge) sda = addr_rw[cnt_bit];
                        if(scl_pedge) begin
                             if(cnt_bit == 0) begin
                                cnt_bit = 7;
                                next_state = RD_ACK;
                             end
                             else cnt_bit = cnt_bit - 1;
                        end
                 end
                 
                 // 4단계 : RD_ACK
                 // SDA 신호를 읽지 않겠다.
                 // 왜냐하면 Direct으로 연결하기 때문에
                 RD_ACK : begin
                        if(scl_nedge) sda = 'bz;   // SDA 신호선으로 부터 데이터를 읽을 수 있기 때문에 끊어준다.
                        else if(scl_pedge) begin
                            if(stop_flag) begin     // stop_flag == 0이면 데이터 보내기 전이기 때문에 next state == SEND_DATA
                                                         // stop_flag == 1이면 데이터 보낸 이후이기 때문에 next state == SCL_STOP
                                stop_flag = 0;
                                next_state = SCL_STOP;
                            end
                            else begin
                                stop_flag = 1;
                                next_state = SEND_DATA;
                             end
                         end
                 end
                 
                 // 5단계 : SEND_DATA
                 SEND_DATA : begin
                        if(scl_nedge) sda = data[cnt_bit];
                        if(scl_pedge) begin
                             if(cnt_bit == 0) begin
                                cnt_bit = 7;
                                next_state = RD_ACK;
                             end
                             else cnt_bit = cnt_bit - 1;
                        end
                 end
                 
                 // 6단계 : SCL_STOP
                 SCL_STOP : begin
                        if(scl_nedge) sda = 0;         // SDA을 Positive edge을 주기 위해 강제로 0으로 
                        else if(scl_pedge) next_state = COMM_STOP;
                 end
                 
                 // 7단계 : COMM_STOP
                 // 바로 SDA의 신호 값을 1로 주면 못받을 수 있기 때문에
                 // 3usec delay time뒤에 SDA의 신호값으 0-> 1로 변화시켜 준다.
                 COMM_STOP : begin
                        if(counter_usec5 >= 3) begin
                            scl_e = 0;
                            sda = 1;
                            next_state = IDLE;
                        end
                 end
            endcase
        end
    end
    
 endmodule 