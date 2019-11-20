module lru_update #(
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input hit,
	input [s_width-1:0] indices [s_width-1:0],
	input [s_width-1:0] hit_indices [s_width-1:0],
	input [s_assoc-2:0] lru_out,
	input valid,
	input [s_width-1:0] hit_valid,
	input [s_width-1:0] way_in,
	output logic [s_assoc-2:0] new_lru,
	output logic hit_update,
	output logic set_index_valid
);

logic hit_update_done;

assign hit_update = hit_valid[s_width-1] && ~hit_update_done;

always_ff @(posedge clk)
begin
    if (hit_valid[s_width-2]) begin
		  if (hit_valid[s_width-1]) 
				hit_update_done <= 1'b1;
		  new_lru[hit_indices[0]] <= ~(way_in[0]);
        for (int i = 1; i < s_width; i++)
            new_lru[hit_indices[i]] <= hit_indices[i-1][0];	 
	 end
	 else if (valid) begin
        hit_update_done <= 1'b0;
		  for (int i = 0; i < s_width; i++)
            new_lru[indices[i]] <= ~lru_out[indices[i]];	 
	 end
	 else begin
	 	  new_lru <= lru_out;
		  hit_update_done <= 1'b0;
	 end

end

endmodule : lru_update