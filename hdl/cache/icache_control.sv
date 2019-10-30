import rv32i_types::*;

module icache_control(
	input clk,
	input mem_read,
	input pmem_resp,
	input hit,
	input lru_out,
	input tag1_hit,
	input tag0_hit,
	input cache_cw_t pipe_cache_cw,
	input cache_cw_t cache_cw,
	output logic pmem_read,
	output logic mem_resp,
	output logic [1:0] load_data,
	output logic [1:0] load_tag,
	output logic set_valid1,
	output logic set_valid0,
	output logic load_lru,
	output logic read_data,
	output logic load_pipeline
);

function void set_defaults();
	load_lru = 1'b0;
	read_data = 1'b0;
	load_data = 2'b0;
	load_tag = 2'b0;
	load_data = 2'b0;
	set_valid1 = 1'b0;
	set_valid0 = 1'b0;
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	load_pipeline = 1'b1;
endfunction

enum int unsigned {
	idle,
	hit_detection,
	load,
	write_data
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	//next state logic
	unique case(state)
		idle: begin
					if(pipe_cache_cw.mem_read)
						next_state = hit_detection;
					else
						next_state = idle;
				end
		hit_detection: next_state = hit ? idle : load;
		load: begin
					if(~pmem_resp)
						next_state = load;
					else
						next_state = write_data;
				end
		write_data: begin
							if(pipe_cache_cw.mem_read)
								next_state = hit_detection;
							else
								next_state = write_data;
						end
	default: next_state = idle;
	endcase
end

always_comb begin
	//state actions
	set_defaults();
	unique case(state)
		idle:	read_data = cache_cw.mem_read;
		hit_detection: if(hit) begin  //do nothing special in the  mem_read case
							load_lru = 1'b1;
							mem_resp = 1'b1;
						end
						else begin
							pmem_read = 1'b1;
						end
		load: if(pmem_resp) begin
					load_data[0] = ~lru_out;
					load_tag[0] = ~lru_out;
					load_data[1] = lru_out;
					load_tag[1] = lru_out;
					set_valid0 = ~lru_out;
					set_valid1 = lru_out;
					read_data = 1'b1; //cache_cw.mem_read  | cache_cw.mem_write ???
				end
				else begin
					pmem_read = 1'b1;
					load_pipeline  = 1'b0; //stall the pipeline
				end
		write_data: ;
	endcase
end

endmodule: icache_control