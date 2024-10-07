`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/28 10:33:54
// Design Name: 
// Module Name: uart_app_control
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


module uart_app_control (
    input clk,
    input reset_p,
    input rx,
    input [15:0] dht11_value,
    output tx
);

    wire [7:0] rec_data;
    reg [7:0] tx_data;
    reg write_uart;
    reg [63:0] data_to_send;
    reg [5:0] byte_index;
    reg [3:0] state;
    wire tx_full;

    uart_top UART_UNIT (
        .clk(clk),
        .reset_p(reset_p),
        .read_uart(1'b0),
        .write_uart(write_uart),
        .rx(rx),
        .write_data(tx_data),
        .rx_full(),
        .rx_empty(),
        .read_data(rec_data),
        .tx_full(tx_full), // tx_full wire connected here
        .tx(tx)
    );

    reg [31:0] timer_count;
    parameter TIMER_MAX = 32'd100_000_000;
    reg timer_tick;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            timer_count <= 32'd0;
            timer_tick <= 1'b0;
        end else begin
            if (timer_count >= TIMER_MAX) begin
                timer_count <= 32'd0;
                timer_tick <= 1'b1;
            end else begin
                timer_count <= timer_count + 1;
                timer_tick <= 1'b0;
            end
        end
    end

    wire [15:0] humi, temp;
    bin_to_dec bcd_humi(.bin({4'b0, dht11_value[15:8]}), .bcd(temp));
    bin_to_dec bcd_temp(.bin({4'b0, dht11_value[7:0]}), .bcd(humi));

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            data_to_send <= 64'b0;
            byte_index <= 6'b0;
            write_uart <= 1'b0;
            tx_data <= 8'b0;
            state <= 4'b0000;
        end else begin
            case (state)
                4'b0000: begin
                    if (timer_tick) begin
                        // Prepare data for transmission
                        data_to_send <= {temp[7:4] + 8'd48, temp[3:0] + 8'd48, 8'h3B, humi[7:4] + 8'd48, humi[3:0] + 8'd48, 8'h3B, 8'h0A};
                        byte_index <= 6'b0;
                        state <= 4'b0001;
                    end
                end
                4'b0001: begin
                    if (byte_index < 6'd8) begin
                        if (!tx_full) begin  // Check if FIFO is not full
                            tx_data <= data_to_send[63:56]; // Load the most significant byte
                            write_uart <= 1'b1;             // Set write_uart to write data into FIFO
                            data_to_send <= data_to_send << 8; // Shift data left to prepare next byte
                            state <= 4'b0010;
                        end
                    end else begin
                        state <= 4'b0000; // Reset to start state
                    end
                end
                4'b0010: begin
                    write_uart <= 1'b0; // Deassert write_uart
                    if (byte_index < 6'd7) begin
                        byte_index <= byte_index + 1;
                        state <= 4'b0001; // Move to the next byte
                    end else begin
                        state <= 4'b0000; // All bytes sent, reset state
                    end
                end
                default: state <= 4'b0000;
            endcase
        end
    end

    wire [15:0] value;
    assign value = {temp[7:0], humi[7:0]};
    fnd_cntr fnd (.clk(clk), .reset_p(reset_p), .value(value), .com(com), .seg_7(seg_7));

endmodule