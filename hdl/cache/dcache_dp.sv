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
	 input addr_sel,
	 input load_pipeline,
	 output logic [s_line-1:0] pmem_wdata,
	 output logic [s_line-1:0] mem_rdata256,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic dirty_ctrl,
	 output logic lru_out,
	 output logic tag1_hit,
	 output logic tag0_hit,
	 output cache_cw_t pipe_cache_cw,
	 output cache_cw_t cache_cw
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
logic [s_tag-1:0] tag_in [1:0];
logic [2:0] index;
logic read_high;
logic valid_in;
logic lru_in;

assign index = addr_sel ? pipe_cache_cw.address[7:5] : mem_address[7:5];
assign read_high = 1'b1;
assign valid_in = 1'b1;

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
	.rindex(pipe_cache_cw.address[7:5]),
	.windex(pipe_cache_cw.address[7:5]),
	.datain(lru_in),
	.dataout(lru_out)
);

// Pipeline CW
cache_cw_reg CW(
	.clk(clk),
	.load(load_pipeline),
	.in(cache_cw),
	.out(pipe_cache_cw)
);


//cache combinational logic and muxes -- pipeline stage 2
assign load_dirty0 = set_dirty0 | clear_dirty0;
assign load_dirty1 = set_dirty1 | clear_dirty1;
assign lru_in = tag0_hit;
assign tag0_hit = (tag_out[0] == pipe_cache_cw.address[31:8]) && (valid_out0 == 1'b1);
assign tag1_hit = (tag_out[1] == pipe_cache_cw.address[31:8]) && (valid_out1 == 1'b1);
assign hit = (tag1_hit) || (tag0_hit);
assign write_en0_sel = {load_data[0], hit};
assign write_en1_sel = {load_data[1], hit};

assign tag_in[0] = pipe_cache_cw.address[31:8];
assign tag_in[1] = pipe_cache_cw.address[31:8];

always_comb begin
	unique case (hit)
        bus_adapter_mux::data: begin
											if({tag1_hit, tag0_hit} == 2'b10) begin
												mem_rdata256= data_out[1];
											end
											else begin
												mem_rdata256= data_out[0];
											end
										 end
		  bus_adapter_mux::pmem_rdata256: mem_rdata256 = data_out[0];
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
      default: datain[0] = pmem_rdata;
	endcase
	 
	unique case (set_dirty1)
		bus_adapter_mux::mem_rdata256: datain[1] = pmem_rdata;
		bus_adapter_mux::mem_wdata256: datain[1] = mem_wdata256;
		default: datain[1] = pmem_rdata;
	endcase
	 
	unique case (write_en0_sel)
		write_en_mux::load_no_hit: write_en_mux_out[0] = 32'hFFFFFFFF;
		write_en_mux::load_and_hit: write_en_mux_out[0] = mem_byte_enable256;
		default: write_en_mux_out[0] = 32'b0;
	endcase
	 
	unique case (write_en1_sel) //change the enumerated type names to be more descriptive
		write_en_mux::load_no_hit: write_en_mux_out[1] = 32'hFFFFFFFF;
		write_en_mux::load_and_hit: write_en_mux_out[1] = mem_byte_enable256;
		default: write_en_mux_out[1] = 32'b0;
	endcase
	
	unique case(lru_out)
		dirty_mux::dirty0: begin
										dirty_ctrl = dirty_out0;
										pmem_wdata = data_out[0];
								 end
								 
		dirty_mux::dirty1: begin
										dirty_ctrl = dirty_out1;
										pmem_wdata = data_out[1];
								 end
		default: 			 begin
										dirty_ctrl = dirty_out0;
										pmem_wdata = data_out[0];
								 end
	endcase
	
	unique case({clear_dirty1, clear_dirty0})
		pmem_addr_mux::mem_addr: pmem_address = pipe_cache_cw.address;
		pmem_addr_mux::way0: pmem_address = {tag_out[0], pipe_cache_cw.address[7:5], 5'b0};
		pmem_addr_mux::way1: pmem_address = {tag_out[1], pipe_cache_cw.address[7:5], 5'b0};
		default: pmem_address = pipe_cache_cw.address;
	endcase

end

endmodule: dcache_dp