import div_types::*;

module divider_control
(
    input logic clk_i,
    input logic reset_n_i,
    input operand_t multiplicand_i,
    input operand_t multiplier_i,
    input logic start_i,
    output logic ready_o,
    output result_t product_o,
    output logic done_o
	 output logic error
);

enum int unsigned {
	start,
	subtract,
	test,
	repetition,
	done
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	unique case(state)
		start:
			next_state = hit_detection;
			
		subtract: 
			next_state = test;
		test: 
			next_state = repetition;
		repetition: 
		begin
			if(counter == 6'd32)
				next_state = DONE;
			else
				next_state = subtract
	default: next_state = start;
	endcase
end

always_comb begin
	set_defaults();
	unique case(state)
		start:	read_data = mem_read | mem_write;
		hit_detection: if(hit) begin
								load_lru = 1'b1;
								mem_resp = 1'b1;
								if(mem_write) begin
									load_data[0] = tag0_hit;
									load_data[1] = tag1_hit;
									set_dirty0 = tag0_hit;
									set_dirty1 = tag1_hit;
								end
							end
							else if(~dirty_ctrl && mem_read) begin
								pmem_read = 1'b1;
							end
		load: if(pmem_resp) begin
					load_data[0] = ~lru_out;
					load_tag[0] = ~lru_out;
					load_data[1] = lru_out;
					load_tag[1] = lru_out;
					set_valid0 = ~lru_out;
					set_valid1 = lru_out;
					load_lru = 1'b1;
					mem_resp = 1'b1;
				end
				else begin
					pmem_read = 1'b1;
				end
		plop: begin
					load_lru = 1'b1;
					mem_resp = 1'b1;
					load_data[0] = ~lru_out;
					load_data[1] = lru_out;
					load_tag[0] = ~lru_out;
					load_tag[1] = lru_out;
					set_dirty0 = ~lru_out;
					set_dirty1 = lru_out;
					set_valid0 = ~lru_out;
					set_valid1 = lru_out;
				end
		store: if(pmem_resp) begin
					pmem_read = 1'b1;
				end
				else begin
					pmem_write = 1'b1;
					clear_dirty0 = ~lru_out;
					clear_dirty1 = lru_out;
				end
	endcase
end

endmodule : l2_cache_control