module pseudo_lru #(
    parameter s_assoc = 8,
    parameter s_width = $clog2(s_assoc),
    parameter s_leaf = (s_assoc/2)-1
)(
	 input clk,
	 input load_lru,
	 output logic [s_width-1:0] way_out,
	 output logic valid
);

//clk,
//read,
//load,
//rindex,
//windex,
//datain,
//dataout

logic [s_assoc-2:0] new_lru;
logic [s_assoc-2:0] lru_out;
logic [s_width-1:0] indices [s_width-1:0];
logic [s_width-1:0] index_valid;

assign indices[0] = 0;
assign index_valid[0] = 1'b1;
assign valid = index_valid[s_width-1];

way_calc #(s_assoc) lru_way_out (
	.lru_out (lru_out),
	.leaf_index (indices[s_width-1]),
	.way_out (way_out)
);

register #(s_assoc-1) lru_reg (
   .clk (clk),
   .load (load_lru),
   .in (new_lru),
   .out (lru_out)
);

lru_index_calc #(s_assoc) index_calculator [s_width-2:0](
	.clk (clk),
	.load(index_valid[s_width-2:0]),
	.load_lru (load_lru),
	.parent (indices[s_width-2:0]),
	.lru_out (lru_out),
	.child (indices[s_width-1:1]),
	.child_valid (index_valid[s_width-1:1])
);

lru_update #(s_assoc) lru_updater(
	.clk (clk),
	.indices (indices),
	.lru_out (lru_out),
	.valid (&(index_valid)),
	.new_lru (new_lru)
);

endmodule : pseudo_lru
