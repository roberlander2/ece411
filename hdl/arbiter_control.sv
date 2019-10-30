module arbiter_control
(
			input clk,
			input iread,
			input pmem_resp,
			input dwrite,
			input dread,
			output logic cache_sel
);


enum int unsigned {
	idle, service_icache, service_dcache
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
	 cache_sel = 1'b0;;
    /* Actions for each state */
	 unique case (state)
		idle:		
		begin
			if(iread  == 1'b1) cache_sel = 1'b0;
			else if ((dread == 1'b1 || dwrite  == 1'b1) && iread  == 1'b0) cache_sel = 1'b1;
			else 	cache_sel = 1'b0;
		end
		
		service_icache:
		begin
			if(pmem_resp == 1'b1 &&  (dread == 1'b1 || dwrite  == 1'b1)) cache_sel = 1'b1;
			else if(pmem_resp == 1'b0) cache_sel = 1'b0;
		end
		
		service_dcache:
		begin
			if(pmem_resp == 1'b1 && iread == 1'b1) cache_sel = 1'b0;
			else if(pmem_resp == 1'b0) cache_sel = 1'b1;
		end
	endcase
end
	
always_comb
begin : next_state_logic
		next_state = state;
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  unique case (state)
	 idle:		
		begin
			if(iread  == 1'b1) next_state = service_icache;
			else if (dread == 1'b1 && dwrite  == 1'b1 && iread  == 1'b0) next_state = service_dcache;
			else next_state = idle;
		end
		
		service_icache:
		begin
			if(pmem_resp == 1'b1 &&  dread == 1'b0 && dwrite  == 1'b0) next_state = idle;
			else if(pmem_resp == 1'b1 &&  (dread == 1'b1 || dwrite  == 1'b1)) next_state = service_dcache;
			else if(pmem_resp == 1'b0) next_state = service_icache;
		end
		
		service_dcache:
		begin
			if(pmem_resp == 1'b1 && iread == 1'b1) next_state = service_icache;
			else if(pmem_resp == 1'b0) next_state = service_dcache;
			else if(pmem_resp == 1'b1 && iread == 1'b0) next_state = idle;
		end
	endcase
end 

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule

