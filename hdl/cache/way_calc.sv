module way_calc #(
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc),
	parameter s_leaf = (s_assoc/2)-1
)(
	input [s_assoc-2:0] lru_out,
	input [s_width-1:0] leaf_index,
	output [s_width-1:0] way_out
);

assign way_out = ((leaf_index - s_leaf) << 1) + lru_out[leaf_index];

endmodule : way_calc