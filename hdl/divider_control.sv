import div_types::*;

module divider_control
(
    input clk,
    input start_i,
	 input dividend_t dividend,
	 input divisor_t divisor,
	 input remainder_t remainder_in,
    input inputs_signed,
	 
	 output logic init,
    output logic load_remainder,
	 output remainder_t remainder_out,
	 output logic div_zero,
	 output logic sign_overflow,
	 output logic ready,
    output logic done
);

logic [6:0] counter;
logic [6:0] counter_new;
logic reset_counter;

assign div_zero = (divisor == 32'b0);
assign sign_overflow = (inputs_signed && (dividend == 32'h80000000) && (divisor == 32'h1));

function void set_defaults();
	done = 1'b0;
	ready = 1'b0;
	init = 1'b0;
	load_remainder = 1'b0;
	reset_counter = 1'b0;
	remainder_out = remainder_in;
	counter_new = counter;
endfunction

enum int unsigned {
	load,
	start,
	subtract,
	test,
	finish
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
	counter <= reset_counter ? 6'd32 : counter_new;
end

always_comb begin
	unique case(state)
		load: next_state = start_i ? start : load;
		start: next_state = (div_zero || sign_overflow) ? finish : subtract;
		subtract: next_state = test;
		test: if(counter == 6'd1)
					next_state = finish;
				else
					next_state = subtract;
		finish: next_state = load;
		default: next_state = load;
	endcase
end

always_comb begin
	set_defaults();
	unique case(state)
		load: if (start_i) begin
					reset_counter = 1'b1;
					init = 1'b1;
					load_remainder = 1'b1;
				end
				else
					ready = 1'b1;
		start: begin
					 if (~(div_zero || sign_overflow)) begin
						remainder_out = remainder_in << 1;
						load_remainder = 1'b1;
					 end
				 end
		subtract: begin
						 remainder_out = {(remainder_in [63:32] - divisor), remainder_in[31:0]};
						 load_remainder = 1'b1;
					 end
		test: begin
					counter_new = counter - 1'b1;
					load_remainder = 1'b1;
					if (remainder_in[63]) begin
						remainder_out = {(remainder_in [63:32] + divisor), remainder_in[31:0]} << 1;
					end
					else begin
						remainder_out = (remainder_in << 1) + 1'b1;
					end
				end
		finish: 	begin
						done = 1'b1;
						ready = 1'b1;
						load_remainder = 1'b1;
						if (~(div_zero || sign_overflow)) begin
							remainder_out = {(remainder_in [63:32] >> 1), remainder_in[31:0]};	
						end
						else begin
							remainder_out = div_zero ? {remainder_in[31:0], 32'hFFFFFFFF} : {32'b0, dividend};
						end
					end
	endcase
end

endmodule : divider_control
