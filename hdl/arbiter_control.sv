import rv32i_types::*;

module arbiter_control
(
			input clk,
			input iread,
			input pmem_resp,
			input dwrite,
			input dread,
			output logic cache_sel,
			output logic pmem_read,
			output logic pmem_write
);


enum int unsigned {
	idle, service_icache, service_dcache
} state, next_state;

function void set_defaults();
	cache_sel = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 unique case (state)
		idle:		
		begin
			if(iread  == 1'b1) 
			begin
				cache_sel = 1'b0;
				pmem_read = 1'b1;
			end
			else if ((dread == 1'b1 || dwrite  == 1'b1) && iread  == 1'b0) 
			begin
				cache_sel = 1'b1;
				pmem_read = dread;
				pmem_write = dwrite;
			end
			else set_defaults();
		end
		
		service_icache:
		begin
			if(pmem_resp == 1'b1 &&  (dread == 1'b1 || dwrite  == 1'b1))
			begin
				cache_sel = 1'b1;
				pmem_read = dread;
				pmem_write = dwrite;
			end
			else if(pmem_resp == 1'b0) pmem_read = 1'b1;
		end
		
		service_dcache:
		begin
			if(pmem_resp == 1'b1 && iread == 1'b1)
			begin
				cache_sel = 1'b0;
				pmem_read = 1'b1;
			end
			else if(pmem_resp == 1'b0) 
			begin
				cache_sel = 1'b1;
				pmem_read = dread;
				pmem_write = dwrite;
			end
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

endmodule

