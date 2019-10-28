import rv32i_types::*;

module arbiter_dp
(
			input iread,
			input [31:0] iaddress,
			input pmem_rdata,
			input pmem_resp,
			input dwrite,
			input [31:0] daddress,
			input [31:0] wdata,
			input dread,
			input cache_sel,
			output logic iresp,
			output logic i_rdata,
			output logic pmem_read,
			output logic [31:0] pmem_wdata,
			output logic [31:0] pmem_address,
			output logic pmem_write,
			output logic d_rdata,
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
		0:	pmem_read = iread;
		1:	pmem_read = dread;
		default: pmem_read = iread;
	endcase
	//pmem_address mux
	unique case (cache_sel)	
		0:	pmem_address = iaddress;
		1:	pmem_address = daddress;
		default: pmem_address = iaddress;
	endcase
	//1 : 2 Decoder
	unique case (cache_sel)	
		0:	iresp = pmem_resp;
		1:	dresp = pmem_resp;
		default: iresp = pmem_resp;
	endcase
	
end
		
endmodule: arbiter_dp
