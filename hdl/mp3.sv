import rv32i_types::*;

module mp3(
	input clk,	
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
logic [255:0] wdata;

// icache and dcache
logic ipmem_read;
logic dpmem_read;	// comment out when not using arbiter
logic dpmem_write;	// comment out when not using arbiter

logic iload_pipeline;
logic dload_pipeline;
logic load_pipeline;

logic stall;

assign load_pipeline = iload_pipeline && dload_pipeline;

// COMMENT TO REMOVE L2
logic arb_l2_read;
logic [255:0] arb_l2_wdata;
rv32i_word arb_l2_address;
logic arb_l2_write;
logic [255:0] arb_l2_rdata;
logic arb_l2_resp;

l2_ret_t arb_ret;
l2_ret_t l2_ret;
l2_go_t arb_go;
l2_go_t l2_go;

assign arb_go.mem_read = arb_l2_read;
assign arb_go.mem_wdata = arb_l2_wdata;
assign arb_go.mem_address = arb_l2_address;
assign arb_go.mem_write = arb_l2_write;
assign arb_l2_rdata = arb_ret.mem_rdata;
assign arb_l2_resp = arb_ret.mem_resp;

datapath dp(.*);

l2_go_reg l2_going(
	.clk	(clk),
   .load (1'b1),
   .in	(arb_go),
   .out	(l2_go)
);

l2_ret_reg l2_return(
	.clk	(clk),
   .load (1'b1),
   .in	(l2_ret),
   .out	(arb_ret)
);

// COMMENT TO REMOVE L2
l2_cache #(5, 4) level_two(
	.clk						(clk),
	.pmem_resp				(pmem_resp),
	.pmem_rdata				(pmem_rdata),
	.l2_go					(l2_go),
	
	.pmem_wdata				(pmem_wdata),
	.pmem_address			(pmem_address),
	.pmem_read				(pmem_read),
	.pmem_write				(pmem_write),
	.l2_ret					(l2_ret)
);

// COMMENT TO REMOVE L2
arbiter arbiter(
	.clk				(clk),
	.iread			(ipmem_read),
	.iaddress		(iaddress),
	.pmem_rdata		(arb_l2_rdata),
	.pmem_resp		(arb_l2_resp),
	.dwrite			(dpmem_write),
	.daddress		(daddress),
	.wdata			(wdata),
	.dread			(dpmem_read),
	
	.iresp			(iresp),
	.i_rdata			(i_rdata),
	.pmem_read		(arb_l2_read),
	.pmem_wdata		(arb_l2_wdata),
	.pmem_address	(arb_l2_address),
	.pmem_write		(arb_l2_write),
	.d_rdata			(d_rdata),
	.dresp			(dresp)
);

 //UNCOMMENT TO REMOVE L2
//arbiter arbiter(
//	.clk				(clk),
//	.iread			(ipmem_read),
//	.iaddress		(iaddress),
//	.pmem_rdata		(pmem_rdata),
//	.pmem_resp		(pmem_resp),
//	.dwrite			(dpmem_write),
//	.daddress		(daddress),
//	.wdata			(wdata),
//	.dread			(dpmem_read),
//	
//	.iresp			(iresp),
//	.i_rdata			(i_rdata),
//	.pmem_read		(pmem_read),
//	.pmem_wdata		(pmem_wdata),
//	.pmem_address	(pmem_address),
//	.pmem_write		(pmem_write),
//	.d_rdata			(d_rdata),
//	.dresp			(dresp)
//);

icache icache(
	.clk					(clk),
	.mem_read			(iread),
	.pmem_resp			(iresp),
	.pmem_rdata			(i_rdata),
	.mem_address		(inst_addr),
	.load_dpipeline 	(dload_pipeline),
	.stall				(stall),
	
	.pmem_read			(ipmem_read),
	.pmem_address		(iaddress),
	.mem_rdata			(inst),
	.load_pipeline 	(iload_pipeline)
);

dcache dcache(
	.clk					(clk),
	.mem_write			(dwrite),
	.mem_read			(dread),
	.pmem_resp			(dresp),
	.pmem_rdata			(d_rdata),
	.mem_wdata			(mem_wdata),
	.mem_address		(mem_address),
	.mem_byte_enable	(mem_byte_enable),
	.load_ipipeline	(iload_pipeline),
	
	.pmem_read			(dpmem_read),
	.pmem_write			(dpmem_write),
	.pmem_wdata			(wdata),
	.pmem_address		(daddress),
	.mem_rdata			(mem_rdata),
	.load_pipeline 	(dload_pipeline)
);

endmodule: mp3