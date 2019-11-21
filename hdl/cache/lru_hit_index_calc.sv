module lru_hit_index_calc #(
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input load,
	input invalidate,
	input [s_width-1:0] child,
	output logic [s_width-1:0] parent,
	output logic parent_valid
);

always_ff @(posedge clk) begin
	if (load && ~invalidate) begin
		parent <= (child - 1'b1) >> 1;
		parent_valid <= 1'b1;
	end
	else begin
		parent <= 0;
		parent_valid <= 1'b0;
	end
end

endmodule : lru_hit_index_calc