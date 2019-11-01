import rv32i_types::*;

module dcache_control(
	input clk,
	input mem_write,
	input mem_read,
	input pmem_resp,
	input hit,
	input dirty_ctrl,
	input lru_out,
	input tag1_hit,
	input tag0_hit,
	input cache_cw_t pipe_cache_cw,
	input cache_cw_t cache_cw,
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
	output logic read_data,
	output logic load_pipeline,
	output logic addr_sel
);

function void set_defaults();
	load_lru = 1'b0;
	read_data = 1'b0;
	load_data = 2'b0;
	load_tag = 2'b0;
	set_valid1 = 1'b0;
	set_valid0 = 1'b0;
	set_dirty0 = 1'b0;
	set_dirty1 = 1'b0;
	clear_dirty1 = 1'b0;
	clear_dirty0 = 1'b0;
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	load_pipeline = 1'b1;
	addr_sel = 1'b0;
endfunction

enum int unsigned {
	idle,
	hit_detection,
	load,
	store,
	write_data
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	//next state logic
	unique case(state)
		idle: begin
					if(cache_cw.mem_read || cache_cw.mem_write)
						next_state = hit_detection;
					else
						next_state = idle;
				end
		hit_detection: next_state = hit ? ((cache_cw.mem_read || cache_cw.mem_write) ? hit_detection : idle) : (dirty_ctrl ? store : load);
		load: begin
					if(~pmem_resp)
						next_state = load;
					else
						next_state = write_data;
				end
		store: begin
					if(~pmem_resp)
						next_state = store;
					else
						next_state = load;
				 end
		write_data: next_state = hit_detection;
	default: next_state = idle;
	endcase
end

always_comb begin
	//state actions
	set_defaults();
	unique case(state)
		idle:	read_data = cache_cw.mem_read | cache_cw.mem_write;
		hit_detection: if(hit) begin  //do nothing special in the  mem_read case
								load_lru = 1'b1;
								mem_resp = 1'b1;
								read_data = cache_cw.mem_read | cache_cw.mem_write;
								if(pipe_cache_cw.mem_write) begin
									load_data[0] = tag0_hit;
									load_data[1] = tag1_hit;
									set_dirty0 = tag0_hit;
									set_dirty1 = tag1_hit;
								end
							end
							else begin
								load_pipeline  = 1'b0; //stall the pipeline
								addr_sel = 1'b1;
								if(dirty_ctrl) begin
									pmem_write = 1'b1;
									clear_dirty0 = ~lru_out;
									clear_dirty1 = lru_out;
								end
								else begin
									pmem_read = 1'b1;
								end
							end
		load: begin
					addr_sel = 1'b1;
					load_pipeline  = 1'b0;
					if(pmem_resp) begin
						load_data[0] = ~lru_out;
						load_data[1] = lru_out;
						load_tag[0] = ~lru_out;
						load_tag[1] = lru_out;
						set_valid0 = ~lru_out;
						set_valid1 = lru_out;
					end
					else begin
						pmem_read = 1'b1;
					end
				end
		store:	begin
						addr_sel = 1'b1;
						load_pipeline  = 1'b0;
						if(pmem_resp) begin
							pmem_read = 1'b1;
						end
						else begin
							pmem_write = 1'b1;
							clear_dirty0 = ~lru_out;
							clear_dirty1 = lru_out;
						end
					end
		write_data:	begin
							load_pipeline = 1'b0;
							read_data = 1'b1;
							addr_sel = 1'b1;
							if(pipe_cache_cw.mem_write) begin
									load_data[0] = ~lru_out;
									load_data[1] = lru_out;
									set_dirty0 = ~lru_out;
									set_dirty1 = lru_out;
							end
						end
	endcase
end


endmodule: dcache_control