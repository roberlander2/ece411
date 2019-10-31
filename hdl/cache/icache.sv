import rv32i_types::*;

module icache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input mem_read,
	input pmem_resp,
	input [s_line-1:0] pmem_rdata,
	input rv32i_word mem_address,
	output logic pmem_read,
	output logic mem_resp,
	output rv32i_word pmem_address,
	output rv32i_word mem_rdata,
	output logic load_pipeline
);

logic tag1_hit;
logic tag0_hit;
logic lru_out;
logic hit;
logic read_data;
logic set_valid1;
logic set_valid0;
logic [1:0] load_data;
logic [1:0] load_tag;
logic load_lru;
logic addr_sel;

logic [s_line-1:0] mem_rdata256;
cache_cw_t pipe_cache_cw;
cache_cw_t cache_cw;

assign mem_rdata = mem_rdata256[(32*pipe_cache_cw.address[4:2]) +: 32];

icache_control icache_ctrl (.*);

icache_dp icache_datapath (.*);

endmodule : icache