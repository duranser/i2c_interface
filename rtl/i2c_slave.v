`timescale 1ns / 1ps



module i2c_slave #(
	parameter IDLE      = 3'b000,
			  START     = 3'b001,
			  ADDRESS   = 3'b010,
			  ACK       = 3'b011,
			  REC_DATA  = 3'b100,
			  SEND_DATA = 3'b101,
			  ACK2      = 3'b110,
			  STOP      = 3'b111
)(
	// System Signals
	input  rst,
	input  [6:0] addr,         // slave address
	input  [7:0] data_rd,  	   // data to be read
	output reg [7:0] data_wr,  // data written
	output reg done,           // wr/rd operation is done
	// I2C Signals
	inout  SDA,
	input  SCL
);
	reg [2:0] state;

	reg SDA_en;
	reg SDA_wr;
	reg [7:0] SDA_rd;

	reg rw;			  // Read/Write, 0->Write, 1->Read
	reg addr_match;   // Address matched or not
	reg [2:0] cnt;
	reg stop_tran;	  // Stop transition (logic-0 to logic-1)
	
	assign SDA = SDA_en ? SDA_wr : 1'bz;
	
	
	// FINITE STATE MACHINE
	always @(posedge SCL, posedge rst)
	begin
		if( rst )
		begin
			state      <= IDLE;
			SDA_en     <= 0;
			SDA_wr     <= 0;
			SDA_rd     <= 0;
			rw		   <= 0;
			addr_match <= 0;
			cnt	       <= 0;
			stop_tran  <= 0;
			data_wr    <= 0;
			done       <= 0;
		end
		else
		begin
			case(state)
			IDLE: begin
				SDA_en    <= 0;
			    done      <= 0;		
				if( SDA )
				begin
					state <= START;
				end
			end
			START: begin
				// START Condition
				if( ~SDA )
				begin
					state  <= ADDRESS;
					cnt    <= 0;
				end
			end
			ADDRESS: begin
				// Receive Address frame
                SDA_rd    <= {SDA_rd[6:0], SDA};    // shift left	
                cnt       <= cnt + 1;		
				if( &cnt )
				begin
					state  <= ACK;
					// If Address is matched
                    if( SDA_rd[6:0] == addr )
                    begin
                        addr_match <= 1;
                        SDA_en     <= 1;
                        SDA_wr     <= 1'b0;
                    end	
                    // Address is not matched, maintain the FSM for next transmissions
                    else
                    begin
                        addr_match <= 0;
                        SDA_en     <= 0;
                    end
				end
			end
			ACK: begin
				// Writing Procedure
				if( ~SDA_rd[0])
				begin
                    SDA_en <= 0;
					state  <= REC_DATA;
					rw     <= 0;
				end
				// Reading Procedure
				else
				begin
					state  <= SEND_DATA;
					rw     <= 1;
                    if( addr_match )
			     	begin
					   SDA_en   <= 1;
					   SDA_wr   <= data_rd[7-cnt];
                       cnt      <= 1;		
				    end						
				end
			end
			REC_DATA: begin
				if( addr_match && ~(&cnt) )
				begin
					SDA_en    <= 0;
					SDA_rd    <= {SDA_rd[6:0], SDA};	// shift left
				end
                
				cnt  <= cnt + 1;		
				if( &cnt )
				begin
					state  <= ACK2;
					// Send ACK
                    if( addr_match )
                    begin
                        SDA_en <= 1;
						SDA_wr <= 1'b0;
				    end                    				
				end
			end
			SEND_DATA: begin
				done <= 0;				
				if( addr_match )
				begin
					SDA_en   <= 1;
					SDA_wr   <= data_rd[7-cnt];
				end
				
                cnt <= cnt + 1;		
				if( &cnt )
				begin
					state  <= ACK2;
					cnt    <= 0;		                  
				end
			end
			ACK2: begin
				SDA_en <= 0;
				// Writing Procedure
				if( ~rw )
				begin
                    state  <= STOP;
				end
			   // Reading Procedure	 
				else
				begin
                    if(SDA)
                    begin
                        state     <= STOP;
                    end
                    else
                    begin
                        state   <= SEND_DATA;
                        done    <= 1;				
                    end		
				end
			end
			STOP: begin
				if( stop_tran )
				begin
					if( SDA )
					begin
						state     <= IDLE;
						done      <= 1;
						stop_tran <= 0;
					end
				end
				else
				begin
					if(~SDA)
						stop_tran <= 1;
				end
			end
			endcase
		end
	end
endmodule