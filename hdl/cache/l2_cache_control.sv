module l2_cache_control #(
	parameter s_assoc  = 8,
	parameter s_width = $clog2(s_assoc)
)(
	input clk,
	input mem_write,
	input mem_read,
	input pmem_resp,
	input hit,
	input dirty_ctrl,
	input [s_width-1:0] lru_out,
	input [s_assoc-1:0] tag_hit,
	input lru_valid,
	output logic pmem_read,
	output logic pmem_write,
	output logic mem_resp,
	output logic [s_assoc-1:0] load_data,
	output logic [s_assoc-1:0] load_tag,
	output logic load_lru,
	output logic [s_assoc-1:0] set_dirty,
	output logic [s_assoc-1:0] clear_dirty,
	output logic [s_assoc-1:0] set_valid,
	output logic read_data
);

logic [s_assoc-1:0] lru_oh;
assign lru_oh = {{(s_assoc-1){1'b0}}, 1'b1};

function void set_defaults();
	load_lru = 1'b0;
	read_data = 1'b0;
	load_data = 0;
	load_tag = 0;
	set_valid = 0;
	set_dirty = 0;
	clear_dirty = 0;
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
endfunction

enum int unsigned {
	idle,
	hit_detection,
	load,
	plop,
	store
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	unique case(state)
		idle: if (mem_read || mem_write)
					next_state = hit_detection;
				else
					next_state = idle;
		hit_detection: begin	//combine into mux? with  select  {hit,miss,dirty}
								if(hit)
									next_state = idle;
								else
									unique case(dirty_ctrl)
										1'b0: next_state = mem_read ? load : plop;
										1'b1: next_state = store;
									endcase
							end 
		load: if(~pmem_resp)
					next_state = load;
				else
					next_state = idle;
		plop: next_state = idle;
		store: if(~pmem_resp)
					next_state = store;
				 else
					next_state = mem_read ? load : plop;
	default: next_state = idle;
	endcase
end

always_comb begin
	set_defaults();
	unique case(state)
		idle:	read_data = mem_read | mem_write;
		hit_detection: if(hit) begin
								load_lru = 1'b1;
								mem_resp = 1'b1;
								if(mem_write) begin
									load_data = tag_hit;
									set_dirty = tag_hit;
								end
							end
							else if(~dirty_ctrl && mem_read) begin
								pmem_read = 1'b1;
							end
		load: if(pmem_resp) begin
					load_data = lru_oh << lru_out;
					load_tag = lru_oh << lru_out;
					set_valid = lru_oh << lru_out;
					load_lru = 1'b1;
					mem_resp = 1'b1;
				end
				else begin
					pmem_read = 1'b1;
				end
		plop: begin
					load_lru = 1'b1;
					mem_resp = 1'b1;
					load_data = lru_oh << lru_out;
					load_tag = lru_oh << lru_out;
					set_valid = lru_oh << lru_out;
					set_dirty = lru_oh << lru_out;
				end
		store: if(pmem_resp) begin
					pmem_read = 1'b1;
				end
				else begin
					pmem_write = lru_valid;
					clear_dirty = lru_oh << lru_out;
				end
	endcase
end

endmodule : l2_cache_control