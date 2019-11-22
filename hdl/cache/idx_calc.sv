module idx_calc #(
	 parameter s_assoc = 16,
    parameter s_width = $clog2(s_assoc),
    parameter s_leaf = (s_assoc/2)-1
)(
    input clk,
	 input [s_width-2:0] lru_out,
    input [s_width-1:0] in,
    output logic [s_width-1:0] dataout
);

endmodule : idx_calc

