module arbiter_control
(
			input clk,
			input iread,
			input pmem_resp,
			input dwrite,
			input dread,
			output logic iresp,
			output logic dresp,
			output logic cache_sel
);

logic dservice;

assign dservice = dread || dwrite;

enum int unsigned {
	idle, service_icache, service_dcache
} state, next_state;

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  unique case (state)
		 idle: 	if(iread) 
						next_state = service_icache;
					else 
						next_state = (dservice) ? service_dcache : idle;
		 service_icache: 	if (pmem_resp)
									next_state = (dservice) ? service_dcache : idle;
								else
									next_state = service_icache;
		 
		 service_dcache: 	if (pmem_resp)
									next_state = (iread) ? service_icache : idle;
								else
									next_state = service_dcache;
	endcase
end 

always_comb
begin : state_actions
	 iresp = 1'b0;
	 dresp = 1'b0;
	 unique case (state)
		idle:	cache_sel = dservice;
		service_icache:	begin
									cache_sel = 1'b0;
									iresp = pmem_resp;
								end
								
		service_dcache:	begin
									cache_sel = 1'b1;
									dresp = pmem_resp;
								end
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule

