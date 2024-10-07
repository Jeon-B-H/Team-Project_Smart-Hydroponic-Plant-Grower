`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/28 10:32:48
// Design Name: 
// Module Name: uart_master
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


module baud_rate_generator
    #(              // 9600 baud
        parameter   N = 10,     // number of counter bits
                    M = 868     // counter limit value
    )
    (
        input clk,       // basys 3 clock
        input reset_p,            // reset
        output tick             // sample tick
    );
    
    // Counter Register
    reg [N-1:0] counter;        // counter value
    wire [N-1:0] next;          // next counter value
    
    // Register Logic
    always @(posedge clk, posedge reset_p)
        if(reset_p)
            counter <= 0;
        else
            counter <= next;
            
    // Next Counter Value Logic
    assign next = (counter == (M-1)) ? 0 : counter + 1;
    
    // Output Logic
    assign tick = (counter == (M-1)) ? 1'b1 : 1'b0;
       
endmodule


module uart_transmitter
    #(
        parameter   DBITS = 8,          // number of data bits
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk,               // basys 3 FPGA
        input reset_p,                    // reset
        input tx_start,                 // begin data transmission (FIFO NOT empty)
        input sample_tick,              // from baud rate generator
        input [DBITS-1:0] data_in,      // data word from FIFO
        output reg tx_done,             // end of transmission
        output tx                       // transmitter data line
    );
    
    // State Machine States
    localparam [1:0]    idle  = 2'b00,
                        start = 2'b01,
                        data  = 2'b10,
                        stop  = 2'b11;
    
    // Registers                    
    reg [1:0] state, next_state;            // state registers
    reg [3:0] tick_reg, tick_next;          // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;        // number of bits transmitted in data state
    reg [DBITS-1:0] data_reg, data_next;    // assembled data word to transmit serially
    reg tx_reg, tx_next;                    // data filter for potential glitches
    
    // Register Logic
    always @(posedge clk or posedge reset_p)
        if(reset_p) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    
    // State Machine Logic
    always @* begin
        next_state = state;
        tx_done = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(state)
            idle: begin                     // no data in FIFO
                tx_next = 1'b1;             // transmit idle
                if(tx_start) begin          // when FIFO is NOT empty
                    next_state = start;
                    tick_next = 0;
                    data_next = data_in;
                end
            end
            
            start: begin
                tx_next = 1'b0;             // start bit
                if(sample_tick)
                    if(tick_reg == 15) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            data: begin
                tx_next = data_reg[0];
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            stop: begin
                tx_next = 1'b1;         // back to idle
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        tx_done = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_reg;
 
endmodule

module uart_receiver
    #(
        parameter   DBITS = 8,          // number of data bits in a data word
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk,               // basys 3 FPGA
        input reset_p,                    // reset
        input rx,                       // receiver data line
        input sample_tick,              // sample tick from baud rate generator
        output reg data_ready,          // signal when new data word is complete (received)
        output [DBITS-1:0] data_out     // data to FIFO
    );
    
    // State Machine States
    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;
    
    // Registers                 
    reg [1:0] state, next_state;        // state registers
    reg [3:0] tick_reg, tick_next;      // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;    // number of bits received in data state
    reg [7:0] data_reg, data_next;      // reassembled data word
    
    // Register Logic
    always @(posedge clk, posedge reset_p)
        if(reset_p) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
        end        

    // State Machine Logic
    always @* begin
        next_state = state;
        data_ready = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        
        case(state)
            idle:
                if(~rx) begin               // when data line goes LOW (start condition)
                    next_state = start;
                    tick_next = 0;
                end
            start:
                if(sample_tick)
                    if(tick_reg == 7) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            data:
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = {rx, data_reg[7:1]};
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            stop:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        data_ready = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
        endcase                    
    end
    
    // Output Logic
    assign data_out = data_reg;

endmodule

module fifo
	#(
	   parameter	DATA_SIZE 	   = 8,	       // number of bits in a data word
				    ADDR_SPACE_EXP = 4	       // number of address bits (2^4 = 16 addresses)
	)
	(
	   input clk,                              // FPGA clock           
	   input reset_p,                            // reset button
	   input write_to_fifo,                    // signal start writing to FIFO
	   input read_from_fifo,                   // signal start reading from FIFO
	   input [DATA_SIZE-1:0] write_data_in,    // data word into FIFO
	   output [DATA_SIZE-1:0] read_data_out,   // data word out of FIFO
	   output empty,                           // FIFO is empty (no read)
	   output full	                           // FIFO is full (no write)
);

	// signal declaration
	reg [DATA_SIZE-1:0] memory [2**ADDR_SPACE_EXP-1:0];		// memory array register
	reg [ADDR_SPACE_EXP-1:0] current_write_addr, current_write_addr_buff, next_write_addr;
	reg [ADDR_SPACE_EXP-1:0] current_read_addr, current_read_addr_buff, next_read_addr;
	reg fifo_full, fifo_empty, full_buff, empty_buff;
	wire write_enabled;
	
	// register file (memory) write operation
	always @(posedge clk)
		if(write_enabled)
			memory[current_write_addr] <= write_data_in;
			
	// register file (memory) read operation
	assign read_data_out = memory[current_read_addr];
	
	// only allow write operation when FIFO is NOT full
	assign write_enabled = write_to_fifo & ~fifo_full;
	
	// FIFO control logic
	// register logic
	always @(posedge clk or posedge reset_p)
		if(reset_p) begin
			current_write_addr 	<= 0;
			current_read_addr 	<= 0;
			fifo_full 			<= 1'b0;
			fifo_empty 			<= 1'b1;       // FIFO is empty after reset
		end
		else begin
			current_write_addr  <= current_write_addr_buff;
			current_read_addr   <= current_read_addr_buff;
			fifo_full  			<= full_buff;
			fifo_empty 			<= empty_buff;
		end

	// next state logic for read and write address pointers
	always @* begin
		// successive pointer values
		next_write_addr = current_write_addr + 1;
		next_read_addr  = current_read_addr + 1;
		
		// default: keep old values
		current_write_addr_buff = current_write_addr;
		current_read_addr_buff  = current_read_addr;
		full_buff  = fifo_full;
		empty_buff = fifo_empty;
		
		// Button press logic
		case({write_to_fifo, read_from_fifo})     // check both buttons
			// 2'b00: neither buttons pressed, do nothing
			
			2'b01:	// read button pressed?
				if(~fifo_empty) begin   // FIFO not empty
					current_read_addr_buff = next_read_addr;
					full_buff = 1'b0;   // after read, FIFO not full anymore
					if(next_read_addr == current_write_addr)
						empty_buff = 1'b1;
				end
			
			2'b10:	// write button pressed?
				if(~fifo_full) begin	// FIFO not full
					current_write_addr_buff = next_write_addr;
					empty_buff = 1'b0;  // after write, FIFO not empty anymore
					if(next_write_addr == current_read_addr)
						full_buff = 1'b1;
				end
				
			2'b11:	begin	// write and read
				current_write_addr_buff = next_write_addr;
				current_read_addr_buff  = next_read_addr;
				end
		endcase			
	end

	// output
	assign full = fifo_full;
	assign empty = fifo_empty;

endmodule


module uart_top
    #(
        parameter   DBITS = 8,          // number of data bits in a word
                    SB_TICK = 16,       // number of stop bit / oversampling ticks
                    BR_LIMIT = 651,     // baud rate generator counter limit
                    BR_BITS = 10,       // number of baud rate generator counter bits
                    FIFO_EXP = 2        // exponent for number of FIFO addresses (2^2 = 4)
    )
    (
        input clk,                      // FPGA clock
        input reset_p,                  // reset
        input read_uart,                // button
        input write_uart,               // button
        input rx,                       // serial data in
        input [DBITS-1:0] write_data,   // data from Tx FIFO
        output tx_full,
        output rx_full,                 // do not write data to FIFO
        output rx_empty,                // no data to read from FIFO
        output tx,                      // serial data out
        output [DBITS-1:0] read_data    // data to Rx FIFO
    );
    
    // Connection Signals
    wire tick;                          // sample tick from baud rate generator
    wire rx_done_tick;                  // data word received
    wire tx_done_tick;                  // data transmission complete
    wire tx_empty;                      // Tx FIFO has no data to transmit
    wire tx_fifo_not_empty;             // Tx FIFO contains data to transmit
    wire [DBITS-1:0] tx_fifo_out;       // from Tx FIFO to UART transmitter
    wire [DBITS-1:0] rx_data_out;       // from UART receiver to Rx FIFO
    
    // Instantiate Modules for UART Core
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk(clk), 
            .reset_p(reset_p),
            .tick(tick)
         );
    
    uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .rx(rx),
            .sample_tick(tick),
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
         );
    
    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .tx_start(tx_fifo_not_empty),
            .sample_tick(tick),
            .data_in(tx_fifo_out),
            .tx_done(tx_done_tick),
            .tx(tx)
         );
    
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_RX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .write_to_fifo(rx_done_tick),
	        .read_from_fifo(read_uart),
	        .write_data_in(rx_data_out),
	        .read_data_out(read_data),
	        .empty(rx_empty),
	        .full(rx_full)            
	      );
	   
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_TX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .write_to_fifo(write_uart),
	        .read_from_fifo(tx_done_tick),
	        .write_data_in(write_data),
	        .read_data_out(tx_fifo_out),
	        .empty(tx_empty),
	        .full(tx_full)                // intentionally disconnected
	      );
    
    // Signal Logic
    assign tx_fifo_not_empty = ~tx_empty;
  
endmodule