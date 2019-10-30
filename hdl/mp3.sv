import rv32i_types::*;

module mp3(
	input clk,
//	/* Port A */
//	output logic read_a,
//   output logic [31:0] address_a,
//   input resp_a,
//   input [31:0] rdata_a,
//
//    /* Port B */
//   output logic read_b,
//	output logic write,
//   output logic [3:0] wmask,
//   output logic [31:0] address_b,
//   output logic [31:0] wdata,    
//	input resp_b,
//   input [31:0] rdata_b,
	
	input pmem_resp,
	input [255:0] pmem_rdata,
	output logic pmem_write,
	output rv32i_word pmem_address,
	output logic [255:0] pmem_wdata,
	output logic pmem_read
	
);

rv32i_word inst; //inputted from the I-Cache
logic iresp;
logic dresp;
logic iread;
logic dread;
logic dwrite;
rv32i_word mem_rdata;
rv32i_word mem_address;
rv32i_word mem_wdata;
rv32i_word inst_addr; //needs to be outputted to the I-Cache
logic [3:0] mem_byte_enable;

//arbiter
rv32i_word iaddress;
rv32i_word daddress;
logic [255:0] i_rdata;
logic [255:0] d_rdata;
rv32i_word wdata;

//assign read_a = iread;
//assign read_b = dread;
//assign write = dwrite;
//assign wmask = mem_byte_enable;
//assign address_b = mem_address;
//assign address_a = inst_addr;
assign wdata = mem_wdata;

//assign iresp = resp_a;
//assign inst = rdata_a;
//assign mem_rdata = rdata_b;
//assign dresp = resp_b;

datapath dp(.*);

arbiter arbiter(.*);

endmodule: mp3