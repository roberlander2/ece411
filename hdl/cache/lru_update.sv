module lru_update #(
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input [s_width-1:0] indices [s_width-1:0],
	input [s_width-1:0] hit_indices [s_width-1:0],
	input [s_assoc-2:0] lru_out,
	input hit_last_index_valid,
	input miss_last_index_valid ,
	input [s_width-1:0] way_in,
	output logic [s_assoc-2:0] new_lru
);

always_ff @(posedge clk)
begin
    if (hit_last_index_valid) begin
		  new_lru[hit_indices[0]] <= ~(way_in[0]);
        for (int i = 1; i < s_width; i++)
            new_lru[hit_indices[i]] <= hit_indices[i-1][0];	 
	 end
	 else if (miss_last_index_valid) begin
		  for (int i = 0; i < s_width; i++)
            new_lru[indices[i]] <= ~lru_out[indices[i]];	 
	 end
	 else begin
	 	  new_lru <= lru_out;
	 end
end

endmodule : lru_update