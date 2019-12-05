module parameter_mux #(
	parameter select_width = 8,
	parameter inout_width = 32
)(
	input [select_width-1:0] onehot_select,
	input [inout_width-1:0] inputs [select_width-1:0],
	input [inout_width-1:0] default_case,
	output logic [inout_width-1:0] out
);

logic [select_width-1:0] selector_base;

assign selector_base = 'b1;

always_comb begin
	out = default_case;
	for(int i = 0; i < select_width; i++) begin
		if (onehot_select == selector_base << i)
			out = inputs[i];
	end
end

endmodule : parameter_mux