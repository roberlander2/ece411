module multi_out_mux #(
	parameter select_width = 8,
	parameter inout_width = 32
)(
	input [select_width-1:0] onehot_select,
	input [inout_width-1:0] input_case,
	input [inout_width-1:0] default_case,
	output logic [inout_width-1:0] out [select_width-1:0]
);

logic [select_width-1:0] selector_base;

assign selector_base = 'b1;

always_comb begin
	for(int i = 0; i < select_width; i++) begin
		out[i] = default_case;
		if (onehot_select == selector_base << i)
			out[i] = input_case;
	end
end

endmodule : multi_out_mux