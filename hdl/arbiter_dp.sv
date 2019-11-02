import rv32i_types::*;

module arbiter_dp
(
			input clk,
			input iread,
			input rv32i_word iaddress,
			input [255:0] pmem_rdata,
			input dwrite,
			input rv32i_word daddress,
			input [255:0] wdata,
			input dread,
			input cache_sel,
			output logic [255:0] i_rdata,
			output logic pmem_read,
			output logic [255:0] pmem_wdata,
			output rv32i_word pmem_address,
			output logic pmem_write,
			output logic [255:0] d_rdata
);

//and gate for pmem_write
assign pmem_write = cache_sel && dwrite;

assign i_rdata = pmem_rdata;
assign d_rdata = pmem_rdata;

assign pmem_wdata = wdata;

//muxes + decoder
always_comb begin	 
	//pmem_read mux
   unique case (cache_sel)	
		1'b0:	begin
					pmem_read = iread;
					pmem_address = iaddress;
				end
		1'b1:	begin
					pmem_read = dread;
					pmem_address = daddress;
				end
		default:	begin
						pmem_read = iread;
						pmem_address = iaddress;
					end
	endcase	
end
		
endmodule: arbiter_dp
