module lru_index_calc #(
   parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input load,
	input invalidate,
	input [s_width-1:0] parent,
	input [s_assoc-2:0] lru_out,
	output logic [s_width-1:0] child,
	output logic child_valid
);

always_ff @(posedge clk) begin
	if (load && ~invalidate) begin
		child <= (parent << 1) + lru_out[parent] + 1'b1;
		child_valid <= 1'b1;
	end
	else begin
		child <= 0;
		child_valid <= 1'b0;
	end
end

endmodule : lru_index_calc