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
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  unique case (state)
		 idle: begin
					if(iread) next_state = service_icache;
					else if (dread || dwrite) next_state = service_dcache;
					else next_state = idle;
				 end
		
		 service_icache: 	if (pmem_resp) begin
									if (dread || dwrite)
										next_state = service_dcache;
									else
										next_state = idle;
								end
								else
									next_state = service_icache;
		 
		 service_dcache: 	if (pmem_resp) begin
									if (iread)
										next_state = service_icache;
									else
										next_state = idle;
								end
								else
									next_state = service_dcache;
	endcase
end 

always_comb
begin : state_actions
	 unique case (state)
		idle:	cache_sel = dread || dwrite;
		service_icache:	cache_sel = 1'b0;
		service_dcache:	cache_sel = 1'b1;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule

