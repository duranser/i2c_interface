`timescale 1ns / 1ps



module i2c_master #(
	parameter SYS_CLK    = 100_000_000,   // 100 MHz
	parameter DATA_RATE0 = 100_000,       // 100 kbps
  			  DATA_RATE1 = 400_000,   	  // 400 kbps
  			  DATA_RATE2 = 1_000_000,     // 1 MHz
  			  DATA_RATE3 = 3_400_000,  	  // 3.4 Mbps		  
	parameter IDLE    = 3'b000,
			  START   = 3'b001,
			  ADDRESS = 3'b010,
			  RD_ACK  =	3'b011,
			  WR_DATA = 3'b100,
			  RD_DATA = 3'b101,
			  RD_ACK2 = 3'b110,
			  STOP    = 3'b111
)(
	// System Signals
	input  clk,			       // System Clock
	input  rst,
	input  write,		       // write request
	input  read,		       // read request
	input  [1:0] speed_mode,   // 00->100 kbps, 01->400 kbps, 10->1 Mbps, 11->3.4 Mbps
	input  [6:0] addr,         // slave address
	input  [7:0] data_wr,      // data to be written
	output reg [7:0] data_rd,  // data read
	output reg done,           // wr/rd operation is done
	output reg ack_error,      // ACK error
	// I2C Signals
	inout  SDA,
	output SCL
);
	reg i2c_clk;
	reg [9:0] clk_cnt;
	reg [9:0] clk_div;
	
	reg [2:0] state;
	reg SDA_en;
	reg SDA_wr;
	reg [7:0] SDA_rd;
	
	reg [7:0] addr_frame;
	reg [7:0] data_frame;
	reg [2:0] cnt;
	
	assign SDA = SDA_en ? SDA_wr : 1'bz;
	assign SCL = i2c_clk;

	// CLK DIVIDER
	always @(posedge clk, posedge rst)
	begin
		if( rst )
		begin
			i2c_clk <= 0;
			clk_cnt <= 0;
			clk_div <= 0;
		end
		else
		begin
			case(speed_mode)
				2'b00: clk_div <= (SYS_CLK/DATA_RATE0)/2;
				2'b01: clk_div <= (SYS_CLK/DATA_RATE1)/2;				
				2'b10: clk_div <= (SYS_CLK/DATA_RATE2)/2;	
				2'b11: clk_div <= (SYS_CLK/DATA_RATE3)/2;		
			endcase
			
			if( clk_cnt == clk_div)
			begin
				i2c_clk <= ~i2c_clk;
				clk_cnt <= 0;
			end
			else
			begin
				clk_cnt <= clk_cnt + 1;
			end			
		end
	end
	
	
	// FINITE STATE MACHINE
	always @(posedge i2c_clk, posedge rst)
	begin
		if( rst )
		begin
			state      <= IDLE;
			SDA_en     <= 1;
			SDA_wr     <= 1;
			SDA_rd     <= 0;
			addr_frame <= 0;
			data_frame <= 0;
			cnt	       <= 0;
			data_rd    <= 0;
			done       <= 0;
			ack_error  <= 0;
		end
		else
		begin
			case(state)
			IDLE: begin
				SDA_en    <= 1;
				SDA_wr    <= 1'b1;	
			    done      <= 0;		
				ack_error <= 0;					
				if( write | read )
				begin
					state 	   <= START;
					// MSB first:
					data_frame <= {data_wr[0], data_wr[1], data_wr[2], data_wr[3], data_wr[4], data_wr[5], data_wr[6], data_wr[7]};
					if( write )
						addr_frame <= {1'b0, addr[0], addr[1], addr[2], addr[3], addr[4], addr[5], addr[6]};
					else
						addr_frame <= {1'b1, addr[0], addr[1], addr[2], addr[3], addr[4], addr[5], addr[6]};
				end
			end
			START: begin
				// START Condition
				SDA_wr <= 0;
				state  <= ADDRESS;
				cnt    <= 0;
			end
			ADDRESS: begin
				// Send Address frame
                SDA_wr <= addr_frame[cnt];
                cnt    <= cnt + 1;
				if( &cnt )
				begin
					state  <= RD_ACK;
				end
			end
			RD_ACK: begin
				SDA_en <= 0;
				// Receive ACK
				if(~SDA_en)
				begin
                    if(~SDA)
                    begin
                        // Writing procedure
                        if( ~addr_frame[7] )
                        begin
                            state  <= WR_DATA;
                            SDA_wr <= data_frame[cnt];
                            SDA_en <= 1;
                            cnt    <= 3'b001;
                        end
                        // Reading procedure
                        else
                        begin
                            state  <= RD_DATA;
                            SDA_en <= 0;
                            cnt    <= 0;
                        end
                    end
                    else
                    begin
                        state     <= IDLE;
			            done      <= 1;				
                        ack_error <= 1'b1;				
                    end
               end
			end
			WR_DATA: begin
                SDA_wr <= data_frame[cnt];
                cnt    <= cnt + 1;
				if( &cnt )
				begin
					state  <= RD_ACK2;
				end
			end
			RD_DATA: begin
                SDA_en  <= 0;
                SDA_rd    <= {SDA_rd[6:0], SDA};    // shift left	
                cnt       <= cnt + 1;		
    			done      <= 0;				
				if( &cnt )
				begin
					state  <= RD_ACK2;
					SDA_en <= 1;
				end
			end
			RD_ACK2: begin
				// Writing Procedure:
				if( ~addr_frame[7] )
				begin
                    SDA_en <= 0;
                    if( ~SDA_en )
                    begin
                        if(~SDA)
                        begin			
                            state  <= STOP;
                            SDA_en <= 1;
                            SDA_wr <= 1'b0;                  
                        end
                        else
                        begin
                            state     <= IDLE;
                            done      <= 1;				
                            ack_error <= 1'b1;
                        end	
                    end
				end
			   // Reading Procedure:		 
				else
				begin
					if(~read)
					begin
                        state   <= STOP;
                        data_rd <= SDA_rd;
                        SDA_en  <= 1;
                        SDA_wr  <= 1'b0;
					end
					else
					begin
                        state   <= RD_DATA;
                        data_rd <= SDA_rd;
                        SDA_en  <= 1;
                        SDA_wr  <= 1'b0;
                        done    <= 1;				
					end		
				end
			end
			STOP: begin
				state   <= IDLE;
			    done    <= 1;				
				SDA_wr  <= 1'b1;
				SDA_en  <= 1;
			end
			endcase
		end
	end
endmodule