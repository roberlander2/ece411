import rv32i_types::*;
import write_en_mux::*;
import dirty_mux::*;
import mem_wdata256mux::*;
import pmem_addr_mux::*;

module l2_cache_datapath  #(
    parameter s_offset = 5,
    parameter s_index  = 3,
	 parameter s_assoc  = 8,
	 parameter s_width = $clog2(s_assoc),
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)(
	 input clk,
	 input [s_line-1:0] mem_wdata,
	 input [s_line-1:0] pmem_rdata,
	 input rv32i_word mem_address,
	 input [s_assoc-1:0] load_lru,
	 input [s_assoc-1:0] load_data,
	 input [s_assoc-1:0] load_tag,
	 input [s_assoc-1:0] set_dirty,
	 input [s_assoc-1:0] clear_dirty,
	 input [s_assoc-1:0] set_valid,
	 input mem_read,
	 input read_data,
	 output logic [s_line-1:0] pmem_wdata,
	 output logic [s_line-1:0] mem_rdata,
	 output rv32i_word pmem_address,
	 output logic hit,
	 output logic dirty_ctrl,
	 output logic [s_width-1:0] lru_out,
	 output logic lru_valid,
	 output logic [s_assoc-1:0] tag_hit
);

logic [s_line-1:0] datain [s_assoc-1:0];
logic [s_line-1:0] data_out[s_assoc-1:0];
logic [s_tag-1:0] tag_out [s_assoc-1:0];
logic [s_assoc-1:0] valid_out;
logic [s_assoc-1:0] dirty_out;
logic [s_assoc-1:0] load_dirty;
logic [s_tag-1:0] tag_in;
logic [s_index-1:0] index;
logic read_high;
logic valid_in;
logic lru_in;

assign index = mem_address[s_offset+s_index-1:s_offset];
assign tag_in = mem_address[31:s_offset+s_index];
assign read_high = 1'b1;
assign valid_in = 1'b1;
assign load_dirty = set_dirty0 | clear_dirty;
assign lru_in = (set_valid0 || set_valid1 || set_dirty0 || set_dirty1) ? (set_valid0 | set_dirty0) : tag0_hit;
assign tag_hit = (tag_out == mem_address[31:s_offset+s_index]) & valid_out;
assign hit = |(tag_hit);

data_array #(s_index, s_offset) line[1:0] (
	.clk(clk),
	.write_en({32{load_data}}),
	.rindex(index),
	.windex(index),
	.read(read_data),
	.datain(datain),
	.dataout(data_out)
);

array #(s_index, s_tag) tag[1:0] (
	.clk(clk),
	.load(load_tag),
	.read(read_data),
	.rindex(index),
	.windex(index),
	.datain(tag_in),
	.dataout(tag_out)
);

array #(s_index, 1) valid1 (
	.clk(clk),
	.load(set_valid1),
	.read(read_data),
	.rindex(index),
	.windex(index),
	.datain(valid_in),
	.dataout(valid_out1)
);

array #(s_index, 1) valid0 (
	.clk(clk),
	.load(set_valid0),
	.read(read_data),
	.rindex(index),
	.windex(index),
	.datain(valid_in),
	.dataout(valid_out0)
);

array #(s_index, 1) dirty1 (
	.clk(clk),
	.load(load_dirty1),
	.read(read_high),
	.rindex(index),
	.windex(index),
	.datain(set_dirty1),
	.dataout(dirty_out1)
);

array #(s_index, 1) dirty0 (
	.clk(clk),
	.load(load_dirty0),
	.read(read_high),
	.rindex(index),
	.windex(index),
	.datain(set_dirty0),
	.dataout(dirty_out0)
);

plru_array #(s_index, s_assoc) plru (
   .clk(clk),
   .read(read_high),
   .load(load_lru),
   .rindex(index),
   .windex(index),
   .tag_hit(tag_hit),
   .dataout(lru_out),
	.valid(lru_valid)
);

//array #(s_index, 1) LRU (
//	.clk(clk),
//	.load(load_lru),
//	.read(read_high),
//	.rindex(index),
//	.windex(index),
//	.datain(lru_in),
//	.dataout(lru_out)
//);

always_comb begin
	//bus adapter inputs and outputs
	unique case (hit)
        bus_adapter_mux::data: unique case (tag0_hit)
											1'b0: mem_rdata = data_out[1];
											1'b1: mem_rdata = data_out[0];
											default: mem_rdata = data_out[0];
										 endcase
		  bus_adapter_mux::pmem_rdata256: mem_rdata = pmem_rdata;
        default: mem_rdata = pmem_rdata;
    endcase
	 
	 unique case (set_dirty0)
        bus_adapter_mux::mem_rdata256: datain[0] = pmem_rdata;
		  bus_adapter_mux::mem_wdata256: datain[0] = mem_wdata;
        default: datain[0] = pmem_rdata;
    endcase
	 
	 unique case (set_dirty1)
	     bus_adapter_mux::mem_rdata256: datain[1] = pmem_rdata;
	     bus_adapter_mux::mem_wdata256: datain[1] = mem_wdata;
		  default: datain[1] = pmem_rdata;
    endcase
	
	//dirty = (dirty0_out & ~lru_out) | (dirty1_out & lru_out);
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
		pmem_addr_mux::mem_addr: pmem_address = mem_address;
		pmem_addr_mux::way0: pmem_address = {tag_out[0], index, 5'b0};
		pmem_addr_mux::way1: pmem_address = {tag_out[1], index, 5'b0};
		default: pmem_address = mem_address;
	endcase
		
end

endmodule : l2_cache_datapath