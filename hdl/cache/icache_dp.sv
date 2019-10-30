import rv32i_types::*;
import write_en_mux::*;
import dirty_mux::*;
import mem_wdata256mux::*;
import pmem_addr_mux::*;
import bus_adapter_mux::*;

module icache_dp #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 input [s_line-1:0] pmem_rdata,
	 input rv32i_word mem_address,
	 input load_lru,
	 input [1:0] load_data,
	 input [1:0] load_tag,
	 input set_valid1,
	 input set_valid0,
	 input mem_read,
	 input read_data,
	 input load_pipeline,
	 output logic [s_line-1:0] mem_rdata256,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic lru_out,
	 output logic tag1_hit,
	 output logic tag0_hit,
	 output cache_cw_t pipe_cache_cw
);

logic [s_line-1:0] datain [1:0];
logic [s_line-1:0] data_out[1:0];
logic [s_mask-1:0] write_en_mux_out [1:0];
logic [s_tag-1:0] tag_out [1:0];
logic valid_out1;
logic valid_out0;
logic write_en1_sel;
logic write_en0_sel;
logic [s_tag-1:0] tag_in;
logic [2:0] index;
logic read_high;
logic valid_in;
logic lru_in;
logic pipe_read;
cache_cw_t cache_cw;

assign index = mem_address[7:5];
assign tag_in = mem_address[31:8];
assign read_high = 1'b1;
assign valid_in = 1'b1;

assign pipe_read = 1'b1;

assign cache_cw.address = mem_address;
assign cache_cw.mem_read = mem_read;

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

array #(s_index ,s_tag) tag[1:0] (
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

array LRU (
	.clk(clk),
	.load(load_lru),
	.read(read_high),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(lru_in),
	.dataout(lru_out)
);
//pipeline signals
logic [s_line-1:0] pipe_data0;
logic [s_line-1:0] pipe_data1;
logic [s_tag-1:0] pipe_tag0;
logic [s_tag-1:0] pipe_tag1;
logic pipe_valid0;
logic pipe_valid1;
logic pipe_lru;

//pipeline registers
data_reg pipe_DATA0(
	.clk(clk),
	.read(pipe_read & load_pipeline),
	.write_en(write_en_mux_out[0]),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(data_out[0]),
	.dataout(pipe_data0)
);

data_reg pipe_DATA1(
	.clk(clk),
	.read(pipe_read & load_pipeline),
	.write_en(write_en_mux_out[1]),
	.rindex(index),
	.windex(cache_cw.address[7:5]),
	.datain(data_out[1]),
	.dataout(pipe_data1)
);

register #(s_tag) pipe_TAG0(
	.clk(clk),
	.load(load_pipeline),
	.in(tag_out[0]),
	.out(pipe_tag0)
);

register #(s_tag) pipe_TAG1(
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


//cache combinational logic and muxes -- pipeline stage 2
assign lru_in = tag0_hit;
assign tag1_hit = (pipe_tag1 == pipe_cache_cw.address[31:8]) && (pipe_valid1 == 1'b1);
assign tag0_hit = (pipe_tag0 == pipe_cache_cw.address[31:8]) && (pipe_valid0 == 1'b1);
assign hit = (tag1_hit) || (tag0_hit);
assign write_en_mux_out[0] = load_data[0] ? 32'hFFFFFFFF : 32'h0;
assign write_en_mux_out[1] = load_data[1] ? 32'hFFFFFFFF : 32'h0;

assign datain[0] = pmem_rdata;
assign datain[1] = pmem_rdata;
assign pmem_address = pipe_cache_cw.address;

always_comb begin
	unique case (hit)
        bus_adapter_mux::data: begin
											if({tag1_hit, tag0_hit} == 2'b10) begin
												mem_rdata256= pipe_data1;
											end
											else begin
												mem_rdata256= pipe_data0;
											end
										 end
		  bus_adapter_mux::pmem_rdata256: mem_rdata256 = pmem_rdata;
        default: mem_rdata256 = pmem_rdata;
    endcase
end

endmodule: icache_dp