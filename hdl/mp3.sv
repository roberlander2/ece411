import rv32i_types::*;

module mp3(
	input clk,
	/* Port A */
	output read_a,
   output [31:0] address_a,
   input logic resp_a,
   input logic [31:0] rdata_a,

    /* Port B */
   output read_b,
	output write,
   output [3:0] wmask,
   output [31:0] address_b,
   output [31:0] wdata,    
	input logic resp_b,
   input logic [31:0] rdata_b
);

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
logic [3:0] mem_byte_enable;

assign read_a = iread;
assign read_b = dread;
assign write = mem_write;
assign wmask = mem_byte_enable;
assign address_b = mem_address;
assign address_a = pc_out;

assign iresp = resp_a;
assign inst = rdata_a;
assign mem_rdata = rdata_b;
assign dresp = resp_b;

datapath dp(.*);

endmodule: mp3