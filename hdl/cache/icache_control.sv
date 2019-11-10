module icache_control(
	input clk,
	input mem_read,
	input pmem_resp,
	input hit,
	input lru_out,
	input tag1_hit,
	input tag0_hit,
	input cache_cw_read,
	input load_dpipeline,
	input stall,
	output logic pmem_read,
	output logic mem_resp,
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
	load_data = 2'b0;
	set_valid1 = 1'b0;
	set_valid0 = 1'b0;
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	load_pipeline = 1'b1;
	set_rdata = 1'b0;
	read_rdata = 1'b0;
endfunction

enum int unsigned {
	idle,
	hit_detection,
	load,
	hold_rdata
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	//next state logic
	unique case(state)
		idle: begin
					if(cache_cw_read)
						next_state = hit_detection;
					else
						next_state = idle;
				end
		hit_detection: begin
									if ((~load_dpipeline  || stall) && mem_resp)
											next_state = hit_detection;
									else
											next_state = hit ? (cache_cw_read ? hit_detection : idle) : load;
								end
		load: begin
					if(~pmem_resp)
						next_state = load;
					else
						next_state = (load_dpipeline && ~stall) ? (cache_cw_read ? hit_detection : idle) : hold_rdata;
				end
		hold_rdata: next_state = (load_dpipeline && ~stall) ? (cache_cw_read ? hit_detection : idle) : hold_rdata;
	default: next_state = idle;
	endcase
end

always_comb begin
	//state actions
	set_defaults();
	unique case(state)
		idle:	read_data = cache_cw_read;
		hit_detection: if(hit || ~load_dpipeline || stall) begin  //do nothing special in the  mem_read case
								load_lru = 1'b1;
								mem_resp = 1'b1;
								read_data = cache_cw_read && load_dpipeline && ~stall;
							end
							else begin
								pmem_read = 1'b1;
								load_pipeline  = 1'b0;;
							end
		load: begin
					if(pmem_resp) begin
						load_data[0] = ~lru_out;
						load_tag[0] = ~lru_out;
						load_data[1] = lru_out;
						load_tag[1] = lru_out;
						set_valid0 = ~lru_out;
						set_valid1 = lru_out;
						mem_resp = 1'b1;
						read_data = cache_cw_read && load_dpipeline && ~stall;
						load_lru = 1'b1;
						set_rdata = 1'b1;
					end
					else begin
						pmem_read = 1'b1;
						load_pipeline = 1'b0;
					end
				end
		hold_rdata:	begin
							mem_resp = 1'b1;
							read_rdata = 1'b1;
							read_data = cache_cw_read && load_dpipeline && ~stall;
						end
	endcase
end

endmodule: icache_control
