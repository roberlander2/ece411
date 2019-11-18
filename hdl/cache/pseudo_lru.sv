import rv32i_types::*;


module pseudo_lru #(
    parameter s_assoc = 16,
    parameter s_width = $clog2(s_assoc),
    parameter s_leaf = (s_assoc/2)-1
)(
	 input clk,
	 input load_lru,
	 output logic [s-width-1:0]way_out
);


endmodule : pseudo_lru
