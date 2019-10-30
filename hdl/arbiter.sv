import rv32i_types::*;

module arbiter
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
		output logic iresp,
		output logic [255:0] i_rdata,
		output logic pmem_read,
		output logic [255:0] pmem_wdata,
		output rv32i_word pmem_address,
		output logic pmem_write,
		output logic [255:0] d_rdata,
		output logic dresp
);


logic cache_sel;

arbiter_dp arbiter_dp(.*);

arbiter_control arbiter_control(.*);

endmodule 