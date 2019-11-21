module pseudo_lru_control (
	input clk,
	input hit,
	output logic hit_load,
	output logic miss_load,
	output logic hit_valid,
	output logic miss_valid,
	output logic lru_valid
);

function void set_defaults();
	hit_load = 1'b0;
	miss_load = 1'b0;
	hit_valid = 1'b0;
	miss_valid = 1'b0;
	lru_valid = 1'b0;
endfunction

enum int unsigned {
	idle, hit_update, miss_update, recalc
} state, next_state;

always_comb
begin : next_state_logic
	  unique case (state)
		 idle: next_state = load_lru ? (hit ? hit_update : miss_update) : idle;
		 hit_update: next_state = recalc;
		 miss_update: next_state = idle;
		 recalc: next_state = idle;
	endcase
end 

always_comb
begin : state_actions
	 set_defaults();
	 unique case (state)
		 idle: lru_valid = 1'b1;
		 hit_update: next_state = 
		 miss_update: next_state = 
		 recalc: next_state = 
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_state;
end

endmodule : pseudo_lru_control