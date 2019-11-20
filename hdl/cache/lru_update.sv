module lru_update #(
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input [s_width-1:0] indices [s_width-1:0],
	input [s_assoc-2:0] lru_out,
	input valid,
	output logic [s_assoc-2:0] new_lru
);

always_ff @(posedge clk)
begin
    if (valid)
        for (int i = 0; i < s_width; i++)
            new_lru[indices[i]] <= ~lru_out[indices[i]];
	 else
		  new_lru <= lru_out;
end

endmodule : lru_update