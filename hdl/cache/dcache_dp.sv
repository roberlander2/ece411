import rv32i_types::*;
import write_en_mux::*;
import dirty_mux::*;
import mem_wdata256mux::*;
import pmem_addr_mux::*;
import bus_adapter_mux::*;

module dcache_dp #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 input [s_line-1:0] mem_wdata256,
	 input [s_line-1:0] pmem_rdata,
	 input [s_mask-1:0] mem_byte_enable256,
	 input rv32i_word mem_address,
	 input load_lru,
	 input [1:0] load_data,
	 input [1:0] load_tag,
	 input set_dirty1,
	 input set_dirty0,
	 input clear_dirty1,
	 input clear_dirty0,
	 input set_valid1,
	 input set_valid0,
	 input mem_read,
	 input mem_write,
	 input read_data,
	 input load_pipeline,
	 output logic [s_line-1:0] pmem_wdata,
	 output logic [s_line-1:0] mem_rdata256,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic dirty_ctrl,
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
logic dirty_out1;
logic dirty_out0;
logic load_dirty1;
logic load_dirty0;
logic [1:0] write_en1_sel;
logic [1:0] write_en0_sel;
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
logic pipe_dirty0;
logic pipe_dirty1;
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


//cache combinational logic and muxes -- pipeline stage 2
assign load_dirty0 = set_dirty0 || clear_dirty0;
assign load_dirty1 = set_dirty1 | clear_dirty1;
assign lru_in = tag0_hit;
assign tag1_hit = (pipe_tag1 == pipe_cache_cw.address[31:8]) && (pipe_valid1 == 1'b1);
assign tag0_hit = (pipe_tag0 == pipe_cache_cw.address[31:8]) && (pipe_valid0 == 1'b1);
assign hit = (tag1_hit) || (tag0_hit);
assign write_en0_sel = {load_data[0], pipe_cache_cw.mem_read};
assign write_en1_sel = {load_data[1], pipe_cache_cw.mem_read};

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
	 
	 
	/*
	*Mux to handle race condtion on reads and writes to the same
	*index is handled within the array
	*can just write directly to  datain of the array
	*/
	unique case (set_dirty0)
        bus_adapter_mux::mem_rdata256: datain[0] = pmem_rdata;
		  bus_adapter_mux::mem_wdata256: datain[0] = mem_wdata256;
        default: datain[0] = mem_rdata256;
    endcase
	 
	 unique case (set_dirty1)
	     bus_adapter_mux::mem_rdata256: datain[1] = pmem_rdata;
	     bus_adapter_mux::mem_wdata256: datain[1] = mem_wdata256;
		  default: datain[1] = mem_rdata256;
    endcase
	 
	 unique case (write_en1_sel) //change the enumerated type names to be more descriptive
		write_en_mux::no_read_or_load: write_en_mux_out[1] = 32'b0;
		write_en_mux::read_no_load: write_en_mux_out[1] = 32'b0;
		write_en_mux::load_no_read: begin
												if(hit) begin
													write_en_mux_out[1] = mem_byte_enable256;
												end
												else begin
													write_en_mux_out[1] = 32'hFFFFFFFF;
												end
											 end
		write_en_mux::load_and_read: write_en_mux_out[1] = 32'hFFFFFFFF;
		default: write_en_mux_out[1] = 32'b0;
	endcase
	
	unique case (write_en0_sel)
		write_en_mux::no_read_or_load: write_en_mux_out[0] = 32'b0;
		write_en_mux::read_no_load: write_en_mux_out[0] = 32'b0;
		write_en_mux::load_no_read: begin
												if(hit) begin
													write_en_mux_out[0] = pipe_cache_cw.mem_byte_enable256;
												end
												else begin
													write_en_mux_out[0] = 32'hFFFFFFFF;
												end
											 end
		write_en_mux::load_and_read: write_en_mux_out[0] = 32'hFFFFFFFF;
		default: write_en_mux_out[0] = 32'b0;
	endcase
	
	unique case(pipe_lru)
		dirty_mux::dirty0: dirty_ctrl = pipe_dirty0;
		dirty_mux::dirty1: dirty_ctrl = pipe_dirty1;
		default: dirty_ctrl = dirty_out0;
	endcase
	
	unique case(lru_out)
		mem_wdata256mux::data0: pmem_wdata = pipe_data0;
		mem_wdata256mux::data1: pmem_wdata = pipe_data1;
		default: pmem_wdata = pipe_data0;
	endcase
	
	unique case({clear_dirty1, clear_dirty0})
		pmem_addr_mux::mem_addr: pmem_address = pipe_cache_cw.address;
		pmem_addr_mux::way0: pmem_address = {pipe_tag0, index, 5'b0};
		pmem_addr_mux::way1: pmem_address = {pipe_tag1, index, 5'b0};
		default: pmem_address = pipe_cache_cw.address;
	endcase

end

endmodule: dcache_dp