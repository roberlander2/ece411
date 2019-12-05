import div_types::*;

module divider
(
    input clk,
	 input start_i,
	 input dividend_t dividend,
    input divisor_t divisor,
	 input inputs_signed,
	 output quotient_t quotient,
    output quotient_t remainder,
	 output logic ready,
	 output logic done
);

logic load_remainder;
logic dividend_pos;
logic divisor_pos;
dividend_t dividend_in;
divisor_t divisor_in;
dividend_t dividend_out;
divisor_t divisor_out;
remainder_t remainder_in;
remainder_t remainder_mux_out;
remainder_t remainder_out;
quotient_t quotient_out;
logic quotient_sign;
logic div_zero;
logic sign_overflow;
logic init;
logic ready_out;
logic done_out;

dividend_t dividend_og;

assign remainder_mux_out = init ? {32'b0, dividend_og} : remainder_in;

assign dividend_pos = inputs_signed ? ~dividend_out[31] : 1'b1;
assign divisor_pos = inputs_signed ? ~divisor_out[31] : 1'b1;
assign quotient_sign = dividend_pos ^ divisor_pos;
assign quotient_out = remainder_out[31:0];
assign quotient = (quotient_sign && ~(div_zero || sign_overflow)) ? ~quotient_out + 1'b1 : quotient_out;
assign remainder = dividend_pos ? remainder_out[63:32] : ~remainder_out[63:32] + 1'b1;

assign dividend_in = dividend_pos ? dividend_out : (~dividend_out) + 1'b1;
assign divisor_in = divisor_pos ? divisor_out : (~divisor_out) + 1'b1;
assign dividend_og = dividend_pos ? dividend : (~dividend) + 1'b1;

register #(64) remainder_reg (
    .clk(clk),
    .load(load_remainder),
    .in(remainder_mux_out),
    .out(remainder_out)
);

register #(32) dividend_reg (
    .clk(clk),
    .load(start_i),
    .in(dividend),
    .out(dividend_out)
);

register #(32) divisor_reg (
    .clk(clk),
    .load(start_i),
    .in(divisor),
    .out(divisor_out)
);

divider_control  control (
    .clk (clk),
    .start_i (start_i),
    .dividend (dividend_in),
    .divisor (divisor_in),
	 .remainder_in(remainder_out),
	 .inputs_signed (inputs_signed),
	 
	 .init (init),
    .load_remainder (load_remainder),
	 .remainder_out (remainder_in),
	 .div_zero (div_zero),
	 .sign_overflow (sign_overflow),
	 .ready (ready_out),
    .done (done_out)
);

always_ff @(posedge clk) begin
	done <= done_out;
	ready <= ready_out;
end

endmodule : divider
