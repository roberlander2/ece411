import rv32i_types::*;
import write_en_mux::*;
import dirty_mux::*;
import mem_wdata256mux::*;
import pmem_addr_mux::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 input [255:0] mem_wdata256,
	 input [255:0] pmem_rdata,
	 input [31:0] mem_byte_enable256,
	 input rv32i_word mem_address,
	 input logic load_lru,
	 input logic [1:0] load_data,
	 input logic [1:0] load_tag,
	 input logic set_dirty1,
	 input logic set_dirty0,
	 input logic clear_dirty1,
	 input logic clear_dirty0,
	 input logic set_valid1,
	 input logic set_valid0,
	 input logic mem_read,
	 input logic read_data,
	 output logic [255:0] pmem_wdata,
	 output logic [255:0] mem_rdata256,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic dirty_ctrl,
	 output logic lru_out,
	 output logic tag1_hit,
	 output logic tag0_hit
);