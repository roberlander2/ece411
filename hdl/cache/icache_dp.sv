import rv32i_types::*;
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
	 input set_rdata,
	 input read_rdata,
	 input load_pipeline,
	 input load_dpipeline,
	 input mem_resp,
	 output logic [s_line-1:0] mem_rdata256,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic lru_out,
	 output logic tag1_hit,
	 output logic tag0_hit,
	 output rv32i_word pipe_cache_cw_addr,
	 output logic cache_cw_read
);

logic [s_line-1:0] datain [1:0];
logic [s_line-1:0] data_out[1:0];
logic [s_mask-1:0] write_en_mux_out [1:0];
logic [s_tag-1:0] tag_out [1:0];
logic valid_out1;
logic valid_out0;
logic write_en1_sel;
logic write_en0_sel;
logic [s_tag-1:0] tag_in [1:0];
logic [2:0] index;
logic read_high;
logic valid_in;
logic lru_in;

logic [s_line-1:0] latched_rdata;

cache_cw_t pipe_cache_cw;
cache_cw_t cache_cw;

assign pipe_cache_cw_addr = pipe_cache_cw.address;
assign cache_cw_read = cache_cw.mem_read;

assign index = cache_cw.address[7:5];
assign read_high = 1'b1;
assign valid_in = 1'b1;

assign cache_cw.address = mem_address;
assign cache_cw.mem_read = mem_read;
assign cache_cw.mem_write = 1'b0;
assign cache_cw.mem_byte_enable = 4'b0;
assign cache_cw.mem_wdata = 32'b0;

//modules
data_array line[1:0] (
	.clk(clk),
	.write_en(write_en_mux_out),
	.rindex(index),
	.windex(pipe_cache_cw.address[7:5]), //should be cw.index but cw has not been implemented yet
	.read(read_data),
	.datain(datain),
	.dataout(data_out)
);

array #(s_index ,s_tag) tag[1:0] (
	.clk(clk),
	.load(load_tag),
	.read(read_data),
	.rindex(index),
	.windex(pipe_cache_cw.address[7:5]),
	.datain(tag_in),
	.dataout(tag_out)
);

array valid1 (
	.clk(clk),
	.load(set_valid1),
	.read(read_high),
	.rindex(index),
	.windex(pipe_cache_cw.address[7:5]),
	.datain(valid_in),
	.dataout(valid_out1)
);

array valid0 (
	.clk(clk),
	.load(set_valid0),
	.read(read_high),
	.rindex(index),
	.windex(pipe_cache_cw.address[7:5]),
	.datain(valid_in),
	.dataout(valid_out0)
);

array LRU (
	.clk(clk),
	.load(load_lru),
	.read(read_high),
	.rindex(pipe_cache_cw.address[7:5]),
	.windex(pipe_cache_cw.address[7:5]),
	.datain(lru_in),
	.dataout(lru_out)
);

// Pipeline CW
cache_cw_reg CW(
	.clk(clk),
	.load((load_pipeline && load_dpipeline) || (load_pipeline && ~load_dpipeline && ~mem_resp)),
	.in(cache_cw),
	.out(pipe_cache_cw)
);

register #(s_line) held_rdata (
    .clk(clk),
    .load(set_rdata),
    .in(pmem_rdata),
    .out(latched_rdata)
);


//cache combinational logic and muxes -- pipeline stage 2
assign lru_in = (set_valid0 || set_valid1) ? set_valid0 : tag0_hit;
assign tag1_hit = (tag_out[1] == pipe_cache_cw.address[31:8]) && valid_out1 && ~read_rdata;
assign tag0_hit = (tag_out[0] == pipe_cache_cw.address[31:8]) && valid_out0 && ~read_rdata;
assign hit = tag1_hit || tag0_hit;
assign write_en_mux_out[0] = {32{load_data[0]}};
assign write_en_mux_out[1] = {32{load_data[1]}};

assign datain[0] = pmem_rdata;
assign datain[1] = pmem_rdata;
assign tag_in[0] = pipe_cache_cw.address[31:8];
assign tag_in[1] = pipe_cache_cw.address[31:8];
assign pmem_address = pipe_cache_cw.address;

always_comb begin
	unique case (hit)
        bus_adapter_mux::data: unique case (tag0_hit)
											1'b0: mem_rdata256 = data_out[1];
											1'b1: mem_rdata256 = data_out[0];
											default: mem_rdata256 = data_out[0];
										 endcase
		  bus_adapter_mux::pmem_rdata256: mem_rdata256 = read_rdata ? latched_rdata : pmem_rdata;
        default: mem_rdata256 = read_rdata ? latched_rdata : pmem_rdata;
    endcase
end

endmodule: icache_dp
