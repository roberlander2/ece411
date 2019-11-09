import rv32i_types::*;

module dcache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input mem_write,
	input mem_read,
	input pmem_resp,
	input [s_line-1:0] pmem_rdata,
	input rv32i_word mem_wdata,
	input rv32i_word mem_address,
	input [3:0] mem_byte_enable,
	input load_ipipeline,
	output logic pmem_read,
	output logic pmem_write,
	output logic [s_line-1:0] pmem_wdata,
	output rv32i_word pmem_address,
	output rv32i_word mem_rdata,
	output logic load_pipeline
);

logic tag1_hit;
logic tag0_hit;
logic lru_out;
logic hit;
logic dirty_ctrl;
logic read_data;
logic set_valid1;
logic set_valid0;
logic set_dirty1;
logic set_dirty0;
logic clear_dirty1;
logic clear_dirty0;
logic [1:0] load_data;
logic [1:0] load_tag;
logic load_lru;
logic set_rdata;
logic read_rdata;
logic mem_resp;

logic [s_line-1:0] mem_wdata256;
logic [s_line-1:0] mem_rdata256;
logic [s_mask-1:0] mem_byte_enable256;

cache_cw_t pipe_cache_cw;
logic cache_cw_read;
logic cache_cw_write;
logic pipe_cache_cw_write;

assign pipe_cache_cw_write = pipe_cache_cw.mem_write;

dcache_control dcache_ctrl (.*);

dcache_dp dcache_datapath (.*);

line_adapter bus_adapter(
    .mem_rdata256 			(mem_rdata256),
    .mem_wdata					(pipe_cache_cw.mem_wdata),
    .mem_byte_enable			(pipe_cache_cw.mem_byte_enable),
    .resp_address				(pipe_cache_cw.address),
    .address					(pipe_cache_cw.address),
	 .mem_wdata256				(mem_wdata256),
	 .mem_byte_enable256		(mem_byte_enable256),
	 .mem_rdata					(mem_rdata)
);

endmodule : dcache