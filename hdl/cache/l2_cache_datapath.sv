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
	 input load_lru,
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
logic [s_mask-1:0] tag_addresses [s_assoc-1:0];
logic [s_mask-1:0] write_en [s_assoc-1:0];

assign index = mem_address[s_offset+s_index-1:s_offset];
assign tag_in = mem_address[s_mask-1:s_offset+s_index];
assign read_high = 1'b1;
assign valid_in = 1'b1;
assign load_dirty = set_dirty | clear_dirty;

genvar i;
generate
	for (i = 0; i < s_assoc; i++) begin : GENERATE_VECTORS
		assign tag_hit[i] = (tag_out[i] == mem_address[s_mask-1:s_offset+s_index]) & valid_out[i];
		assign tag_addresses[i] = {tag_hit[i], index, {s_offset{1'b0}}};
		assign write_en[i] = {s_mask{load_data[i]}};
	end
endgenerate

assign hit = |(tag_hit);
assign dirty_ctrl = dirty_out[lru_out];
assign pmem_wdata = data_out[lru_out];

data_array #(s_index, s_offset) line[s_assoc-1:0] (
	.clk(clk),
	.write_en(write_en),
	.rindex(index),
	.windex(index),
	.read(read_data),
	.datain(datain),
	.dataout(data_out)
);

array #(s_index, s_tag) tag[s_assoc-1:0] (
	.clk(clk),
	.load(load_tag),
	.read(read_data),
	.rindex(index),
	.windex(index),
	.datain(tag_in),
	.dataout(tag_out)
);

array #(s_index, 1) valid [s_assoc-1:0] (
	.clk(clk),
	.load(set_valid),
	.read(read_data),
	.rindex(index),
	.windex(index),
	.datain(valid_in),
	.dataout(valid_out)
);

array #(s_index, 1) dirty [s_assoc-1:0] (
	.clk(clk),
	.load(load_dirty),
	.read(read_high),
	.rindex(index),
	.windex(index),
	.datain(set_dirty),
	.dataout(dirty_out)
);

plru_array #(s_index, s_assoc) plru (
   .clk(clk),
   .read(read_high),
   .load(load_lru),
   .index(index),
   .tag_hit(tag_hit),
   .dataout(lru_out),
	.valid(lru_valid)
);

parameter_mux #(s_assoc, s_line) bus_adapter_rdata_mux (
	.onehot_select (tag_hit),
	.inputs (data_out),
	.default_case (pmem_rdata),
	.out (mem_rdata)
);

multi_out_mux #(s_assoc, s_line) bus_adapter_datain_mux (
	.onehot_select (set_dirty),
	.input_case (mem_wdata),
	.default_case (pmem_rdata),
	.out (datain)
);

parameter_mux #(s_assoc, s_mask) bus_adapter_pmem_addr_mux (
	.onehot_select (clear_dirty),
	.inputs (tag_addresses),
	.default_case (mem_address),
	.out (pmem_address)
);

endmodule : l2_cache_datapath