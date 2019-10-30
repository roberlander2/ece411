import rv32i_types::*;

module arbiter_dp
(
			input clk,
			input iread,
			input rv32i_word iaddress,
			input [255:0] pmem_rdata,
			input pmem_resp,
			input dwrite,
			input rv32i_word daddress,
			input rv32i_word wdata,
			input dread,
			input cache_sel,
			output logic iresp,
			output logic [255:0] i_rdata,
			output logic pmem_read,
			output logic [255:0] pmem_wdata,
			output rv32i_word pmem_address,
			output logic pmem_write,
			output logic [255:0] d_rdata,
			output logic dresp
);

//and gate for pmem_write
assign pmem_write = (cache_sel & dwrite);

assign i_rdata = pmem_rdata;
assign d_rdata = pmem_rdata;

assign pmem_wdata = wdata;

//muxes + decoder
always_comb begin	 
	//pmem_read mux
   unique case (cache_sel)	
		1'b0:	pmem_read = iread;
		1'b1:	pmem_read = dread;
		default: pmem_read = iread;
	endcase
	//pmem_address mux
	unique case (cache_sel)	
		1'b0:	pmem_address = iaddress;
		1'b1:	pmem_address = daddress;
		default: pmem_address = iaddress;
	endcase
	//1 : 2 Decoder
	unique case (cache_sel)	
		1'b0:	
		begin
			iresp = pmem_resp;
			dresp = 1'b0;
		end
		1'b1:	
		begin 
			dresp = pmem_resp;
			iresp = 1'b0;
		end
		default: 
		begin
			iresp = pmem_resp;
			dresp = 1'b0;
		end
	endcase
	
end
		
endmodule: arbiter_dp
