import rv32i_types::*;

module selector
(
	input logic clk,
	input logic load,
	input logic read,
	input logic pred_used,
	input logic resolution,
	output logic pred_sel
);

selector_t data = local_lt;
selector_t _update;
logic _pred_sel;

assign pred_sel = (read) ? _pred_sel : 1'b0;
always_comb begin
	unique case (data)
		local_st: begin
						if(resolution)
							_update = local_st;
						else
							_update = local_lt;
						_pred_sel = 0;
					 end
		local_lt: begin
						if(resolution)
							_update = local_st;
						else
							_update = global_lt;
						_pred_sel = 0;
					 end
		global_lt: begin
						if(resolution)
							_update = global_st;
						else
							_update = local_lt;
						_pred_sel = 1;
					  end
		global_st: begin
						if(resolution)
							_update = global_st;
						else
							_update = global_lt;
						_pred_sel = 1;
					  end
		default: _update = local_st;
	endcase
	
	
end

always_ff @(posedge clk) begin
	if(load)
		data <= _update;
end

endmodule : selector
