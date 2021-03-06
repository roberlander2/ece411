module l2_cache_control (
	input clk,
	input logic mem_write,
	input logic mem_read,
	input logic pmem_resp,
	input logic hit,
	input logic dirty_ctrl,
	input logic lru_out,
	input logic tag1_hit,
	input logic tag0_hit,
	output logic pmem_read,
	output logic pmem_write,
	output logic mem_resp,
	output logic set_dirty1,
	output logic set_dirty0,
	output logic clear_dirty1,
	output logic clear_dirty0,
	output logic [1:0] load_data,
	output logic [1:0] load_tag,
	output logic set_valid1,
	output logic set_valid0,
	output logic load_lru,
	output logic read_data
);

function void set_defaults();
	load_lru = 1'b0;
	read_data = 1'b0;
	load_data = 2'b0;
	load_tag = 2'b0;
	load_data = 2'b0;
	set_valid1 = 1'b0;
	set_valid0 = 1'b0;
	set_dirty0 = 1'b0;
	set_dirty1 = 1'b0;
	clear_dirty1 = 1'b0;
	clear_dirty0 = 1'b0;
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
endfunction

enum int unsigned {
	idle,
	go_update,
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
		go_update: next_state = idle;
		hit_detection: begin	//combine into mux? with  select  {hit,miss,dirty}
								if(hit)
									next_state = go_update;
								else
									unique case(dirty_ctrl)
										1'b0: next_state = mem_read ? load : plop;
										1'b1: next_state = store;
									endcase
							end 
		load: if(~pmem_resp)
					next_state = load;
				else
					next_state = go_update;
		plop: next_state = go_update;
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
		default: ;
	endcase
end

endmodule : l2_cache_control