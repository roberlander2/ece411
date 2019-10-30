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
rv32i_word wdata;

// icache and dcache
logic icache_resp;
logic dcache_resp;
logic ipmem_read;
logic dpmem_read;
logic dpmem_write;

logic iload_pipeline;
logic dload_pipeline;
logic load_pipeline;

assign load_pipeline = iload_pipeline & dload_pipeline;

datapath dp(.*);

arbiter arbiter(
	.clk				(clk),
	.iread			(ipmem_read),
	.iaddress		(iaddress),
	.pmem_rdata		(pmem_rdata),
	.pmem_resp		(pmem_resp),
	.dwrite			(dpmem_write),
	.daddress		(daddress),
	.wdata			(wdata),
	.dread			(dpmem_read),
	.iresp			(iresp),
	.i_rdata			(i_rdata),
	.pmem_read		(pmem_read),
	.pmem_wdata		(pmem_wdata),
	.pmem_address	(pmem_address),
	.pmem_write		(pmem_write),
	.d_rdata			(d_rdata),
	.dresp			(dresp)
);

icache icache(
	.clk				(clk),
	.mem_read		(iread),
	.pmem_resp		(iresp),
	.pmem_rdata		(i_rdata),
	.mem_address	(inst_addr),
	.pmem_read		(ipmem_read),
	.mem_resp		(icache_resp),
	.pmem_address	(iaddress),
	.mem_rdata		(inst),
	.load_pipeline (iload_pipeline)
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
	.pmem_read			(dpmem_read),
	.pmem_write			(dpmem_write),
	.mem_resp			(dcache_resp),
	.pmem_wdata			(wdata),
	.pmem_address		(daddress),
	.mem_rdata			(mem_rdata),
	.load_pipeline 	(dload_pipeline)
);

endmodule: mp3