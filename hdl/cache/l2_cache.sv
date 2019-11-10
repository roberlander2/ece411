import rv32i_types::*;

module l2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rv32i_word mem_address,
	input [s_line-1:0] mem_wdata,
	input logic mem_read,
	input logic mem_write,
	input logic pmem_resp,
	input [s_line-1:0] pmem_rdata,
//	output [s_line-1:0] mem_rdata,
	output logic [s_line-1:0] pmem_wdata,
	output rv32i_word pmem_address,
	output logic pmem_read,
	output logic pmem_write,
	output l2_ret_t l2_ret
//	output logic mem_resp
);

logic hit;
logic tag1_hit;
logic tag0_hit;
logic load_lru;
logic [1:0] load_data;
logic [1:0] load_tag;
logic set_dirty0;
logic clear_dirty0;
logic set_dirty1;
logic clear_dirty1;
logic read_data;
logic set_valid1;
logic set_valid0;
logic dirty_ctrl;
logic lru_out;

logic mem_resp;
logic [s_line-1:0] mem_rdata;

assign l2_ret.mem_resp = mem_resp;
assign l2_ret.mem_rdata = mem_rdata;

l2_cache_control control(.*);

l2_cache_datapath #(s_offset, s_index) datapath(.*);

endmodule : l2_cache