import rv32i_types::*;
import write_en_mux::*;
import dirty_mux::*;
import mem_wdata256mux::*;
import pmem_addr_mux::*;

module cache_dp #(
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
	 input logic mem_write,
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

logic [255:0] datain [1:0];
logic [255:0] data_out[1:0];
logic [31:0] write_en_mux_out [1:0];
logic [23:0] tag_out [1:0];
logic valid_out1;
logic valid_out0;
logic dirty_out1;
logic dirty_out0;
logic load_dirty1;
logic load_dirty0;
logic [1:0] write_en1_sel;
logic [1:0] write_en0_sel;
logic [23:0] tag_in;
logic [2:0] index;
logic read_high;
logic valid_in;
logic lru_in;
cache_cw_t cache_cw;

assign index = mem_address[7:5];
assign tag_in = mem_address[31:8];
assign read_high = 1'b1;
assign valid_in = 1'b1;
assign load_dirty0 = set_dirty0 || clear_dirty0;
assign load_dirty1 = set_dirty1 | clear_dirty1;
assign lru_in = tag0_hit;
assign tag1_hit = (tag_out[1] == mem_address[31:8]) && (valid_out1 == 1'b1);
assign tag0_hit = (tag_out[0] == mem_address[31:8]) && (valid_out0 == 1'b1);
assign hit = (tag1_hit) || (tag0_hit);

assign write_en0_sel = {load_data[0], mem_read};
assign write_en1_sel = {load_data[1], mem_read};
assign data_sel = (index & cache_cw.address[7:5]);
assign pipe_read = 1'b1;

assign cache_cw.address = mem_address;
assign cache_cw.mem_read = mem_read;
assign cache_cw.mem_write = mem_write;
assign cache_cw.mem_byte_enable256 = mem_byte_enable256;
assign cache_cw.mem_wdata256 =  mem_wdata256;

//modules
data_array line[1:0] (
	.clk(clk),
	.write_en(write_en_mux_out),
	.rindex(index),
	.windex(cache_cw.address[7:5]), //should be cw.index but cw has not been implemented yet
	.read(read_data),
	.datain(datain),
	.dataout(data_out)
);

array #(3,24) tag[1:0] (
	.clk(clk),
	.load(load_tag),
	.read(read_data),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(tag_in),
	.dataout(tag_out)
);

array valid1 (
	.clk(clk),
	.load(set_valid1),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(valid_in),
	.dataout(valid_out1)
);

array valid0 (
	.clk(clk),
	.load(set_valid0),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(valid_in),
	.dataout(valid_out0)
);

array dirty1 (
	.clk(clk),
	.load(load_dirty1),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(load_dirty1),
	.dataout(dirty_out1)
);

array dirty0 (
	.clk(clk),
	.load(load_dirty0),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(load_dirty0),
	.dataout(dirty_out0)
);

array #(3, 1) LRU (
	.clk(clk),
	.load(load_lru),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(lru_in),
	.dataout(lru_out)
);
//pipeline signals
logic [255:0] pipe_data0;
logic [255:0] pipe_data1;
logic [23:0] pipe_tag0;
logic [23:0] pipe_tag1;
logic pipe_valid0;
logic pipe_valid1;
logic pipe_dirty0;
logic pipe_dirty1;
logic pipe_lru;

//pipeline registers
data_reg pipe_DATA0(
	.clk(clk),
	.read(pipe_read & load_pipeline),
	.write_en(write_en_mux_out),
	.data_sel(data_sel),
	.datain(data_out[0]),
	.dataout(pipe_data0)
);

data_reg pipe_DATA1(
	.clk(clk),
	.read(pipe_read & load_pipeline),
	.write_en(write_en_mux_out),
	.datain(data_out[1]),
	.dataout(pipe_data1)
);

register #(24) pipe_TAG0(
	.clk(clk),
	.load(load_pipeline),
	.in(tag_out[0]),
	.out(pipe_tag0)
);

register #(24) pipe_TAG1(
	.clk(clk),
	.load(load_pipeline),
	.in(tag_out[1]),
	.out(pipe_tag1)
);

register #(1) pipe_VALID0(
	.clk(clk),
	.load(load_pipeline),
	.in(valid_out0),
	.out(pipe_valid0)
);

register #(1) pipe_VALID1(
	.clk(clk),
	.load(load_pipeline),
	.in(valid_out1),
	.out(pipe_valid1)
);

register #(1) pipe_DIRTY0(
	.clk(clk),
	.load(load_pipeline),
	.in(dirty_out0),
	.out(pipe_dirty0)
);

register #(1) pipe_DIRTY1(
	.clk(clk),
	.load(load_pipeline),
	.in(dirty_out1),
	.out(pipe_dirty1)
);

register #(1) pipe_LRU(
	.clk(clk),
	.load(load_pipeline),
	.in(lru_out),
	.out(pipe_lru)
);

cache_cw_reg CW(
	.clk(clk),
	.load(load_pipeline),
	.in(cache_cw),
	.out(pipe_cache_cw)
);

endmodule: cache_dp