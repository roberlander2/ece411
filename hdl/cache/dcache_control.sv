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
	input pipe_cache_cw_write,
	input cache_cw_read,
	input cache_cw_write,
	input load_ipipeline,
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
	output logic set_rdata,
	output logic read_rdata
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
	set_rdata = 1'b0;
	read_rdata = 1'b0;
endfunction

enum int unsigned {
	idle,
	hit_detection,
	load,
	store,
	write_data,
	hold
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	//next state logic
	unique case(state)
		idle: if(cache_cw_read || cache_cw_write)
					next_state = hit_detection;
				else
					next_state = idle;
		hit_detection: if (~load_ipipeline && mem_resp)
								next_state = hold;
							else
								next_state = hit ? ((cache_cw_read || cache_cw_write) ? hit_detection : idle) : (dirty_ctrl ? store : load);
		load: if(~pmem_resp)
					next_state = load;
				else begin
					if (pipe_cache_cw_write)
						next_state = write_data;
					else
						next_state = load_ipipeline ? ((cache_cw_read || cache_cw_write)? hit_detection : idle) : hold;
				end
		store: 	if(~pmem_resp)
						next_state = store;
					else
						next_state = load;
		write_data: next_state = load_ipipeline ? ((cache_cw_read || cache_cw_write)? hit_detection : idle) : hold;
		hold: next_state = load_ipipeline ? ((cache_cw_read || cache_cw_write) ? hit_detection : idle) : hold;
		default: next_state = idle;
	endcase
end

always_comb begin
	//state actions
	set_defaults();
	unique case(state)
		idle:	read_data = cache_cw_read | cache_cw_write;
		hit_detection: if(hit) begin  //do nothing special in the  mem_read case
								load_lru = 1'b1;
								mem_resp = 1'b1;
								read_data = (cache_cw_read | cache_cw_write) && load_ipipeline;
								if(pipe_cache_cw_write) begin
									load_data[0] = tag0_hit;
									load_data[1] = tag1_hit;
									set_dirty0 = tag0_hit;
									set_dirty1 = tag1_hit;
								end
							end
							else begin
								load_pipeline = 1'b0;
								if(~dirty_ctrl) begin
									pmem_read = 1'b1;
								end
							end
		load: begin
					load_pipeline = 1'b0;
					if(pmem_resp) begin
						load_data[0] = ~lru_out;
						load_data[1] = lru_out;
						load_tag[0] = ~lru_out;
						load_tag[1] = lru_out;
						set_valid0 = ~lru_out;
						set_valid1 = lru_out;
						if (~pipe_cache_cw_write) begin
							mem_resp = 1'b1;
							load_lru = 1'b1;
							read_data = (cache_cw_read | cache_cw_write) && load_ipipeline;
							set_rdata = 1'b1;
							load_pipeline = 1'b1;
						end
					end
					else begin
						pmem_read = 1'b1;
					end
				end
		store:	begin
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
		write_data: begin
							mem_resp = 1'b1;
							load_data[0] = ~lru_out;
							load_data[1] = lru_out;
							set_dirty0 = ~lru_out;
							set_dirty1 = lru_out;
							load_lru = 1'b1;
							read_data = (cache_cw_read | cache_cw_write) && load_ipipeline;
						end
		hold:	begin
					mem_resp = 1'b1;
					read_rdata = 1'b1;
					read_data = (cache_cw_read | cache_cw_write) && load_ipipeline;
				end
	endcase
end


endmodule: dcache_control
