import rv32i_types::*;

module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
	 parameter s_assoc  = 8,
	 parameter s_width = $clog2(s_assoc),
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
//	input rv32i_word mem_address,
//	input [s_line-1:0] mem_wdata,
//	input logic mem_read,
//	input logic mem_write,
	input logic pmem_resp,
	input [s_line-1:0] pmem_rdata,
	input l2_go_t l2_go,
//	output [s_line-1:0] mem_rdata,
	output logic [s_line-1:0] pmem_wdata,
	output rv32i_word pmem_address,
	output logic pmem_read,
	output logic pmem_write,
	output l2_ret_t l2_ret
//	output logic mem_resp
);

logic hit;
logic [s_assoc-1:0] tag_hit;
logic load_lru;
logic [s_assoc-1:0] load_data;
logic [s_assoc-1:0] load_tag;
logic [s_assoc-1:0] set_dirty;
logic [s_assoc-1:0] clear_dirty;
logic [s_assoc-1:0] set_valid;
logic read_data;
logic dirty_ctrl;
logic [s_width-1:0] lru_out;
logic lru_valid;

logic mem_resp;
logic [s_line-1:0] mem_rdata;

rv32i_word mem_address;
logic [s_line-1:0] mem_wdata;
logic mem_read;
logic mem_write;

assign l2_ret.mem_resp = mem_resp;
assign l2_ret.mem_rdata = mem_rdata;

assign mem_address = l2_go.mem_address;
assign mem_wdata = l2_go.mem_wdata;
assign mem_read = l2_go.mem_read;
assign mem_write = l2_go.mem_write;

l2_cache_control #(s_assoc) control(.*);

l2_cache_datapath #(s_offset, s_index, s_assoc) datapath(.*);

endmodule : l2_cache