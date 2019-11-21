module pseudo_lru_control (
	input clk,
	input hit,
	input hit_last_index_valid,
	input miss_last_index_valid,
	input way_valid,
	input load_lru,
	output logic hit_valid,
	output logic miss_valid,
	output logic hit_update,
	output logic miss_update,
	output logic lru_valid,
	output logic indices_invalid
);

function void set_defaults();
	hit_valid = 1'b0;
	miss_valid = 1'b0;
	lru_valid = 1'b0;
	hit_update = 1'b0;
	miss_update = 1'b0;
	indices_invalid = 1'b0;
endfunction

enum int unsigned {
	idle, lru_hit, lru_miss, recalc
} state, next_state;

always_comb
begin : next_state_logic
	  unique case (state)
		 idle: next_state = load_lru ? (hit ? lru_hit : lru_miss) : idle;
		 lru_hit: next_state = hit_last_index_valid ? recalc : lru_hit;
		 lru_miss: next_state = miss_last_index_valid ? recalc : lru_miss;
		 recalc: next_state = way_valid ? idle : recalc;
	endcase
end 

always_comb
begin : state_actions
	 set_defaults();
	 unique case (state)
		 idle: begin
					 lru_valid = 1'b1;
					 miss_valid = 1'b1;
				 end
		 lru_hit: begin
						 hit_valid = 1'b1;
						 if (hit_last_index_valid) begin
								hit_update = 1'b1;
								indices_invalid = 1'b1;
						 end
					 end
		 lru_miss: begin
						  miss_valid = 1'b1;
						  if (miss_last_index_valid) begin
								miss_update = 1'b1;
								indices_invalid = 1'b1;
						  end
					  end
		 recalc: begin
						miss_valid = 1'b1;
					end
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_state;
end

endmodule : pseudo_lru_control