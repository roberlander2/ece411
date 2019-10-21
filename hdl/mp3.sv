import rv32i_types::*;

module mp3(
	input clk

);

assign inst = rdata_a;
assign address_a = pc_out;
assign read_a = iread; //signal from dp or just leave  high?
assign iresp = resp_a;

assign wdata = mem_wdata;
assign write = mem_write;
assign read_b = dread;
assign wmask = mem_byte_enable;
assign address_b = mem_address;
assign dresp = resp_b;
assign mem_rdata = r_data_b;

rv32i_word inst; //inputted from the I-Cache
logic iresp;
logic dresp;
logic iread;
logic dread;
logic mem_write;
rv32i_word mem_rdata;
rv32i_word mem_address;
rv32i_word mem_wdata;
rv32i_word pc_out; //needs to be outputted to the I-Cache
logic [3:0] mem_byte_enable

datapath dp(.*);

/* Port A emulates ICache */
logic read_a;
logic [31:0] address_a;
logic resp_a;
logic [31:0] rdata_a;

/* Port B emulates DCache */
logic read_b;
logic write;
logic [3:0] wmask;
logic [31:0] address_b;
logic [31:0] wdata;
logic resp_b;
logic [31:0] rdata_b;

magic_memory_dp(.*);

endmodule: mp3