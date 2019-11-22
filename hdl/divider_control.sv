import div_types::*;

module divider_control
(
    input logic clk,  //was clk_i? not sure why
    input dividend_t dividend_i,
    input divisor_t divisor_i,
    input logic start_i,
    input logic _signed,
    output logic load_divisor,
    output logic load_remainder,
    output divisor_t divisor_in,
    output remainder_t remainder_in,
    output quotient_t actual_remainder, //didnt feel like making another type
    output quotient_t quotient,
    output logic done_bit
	 //output logic error
);

logic [6:0] counter;
logic dividend;
logic sign_bit;

assign dividend = dividend_i;
assign actual_remainder = remainder_in[63:32];
assign quotient = remainder_in[31:0];
assign divisor_in = divisor_i;
//assign load_divisor = 1'b1;
//assign load_remainder = 1'b1

function void set_defaults();
	done_bit = 1''b0;
  load_divisor = 1'b1;
  load_remainder = 1'b1;
endfunction

enum int unsigned {
  load,
  start,
	subtract,
	test,
	done
} state, next_state;

always_ff @(posedge clk) begin
	state <= next_state;
end

always_comb begin
	unique case(state)
    load:
      next_state = start;
		start:
			next_state = hit_detection;

		subtract:
			next_state = test;
		test:
		begin
			if(counter == 6'd32)
				next_state = done;
			else
				next_state = subtract
	default: next_state = start;
	endcase
end

always_comb begin
	set_defaults();
	unique case(state)
    load: //may or may not need this state i'm not sure
    begin
      remainder_in = {32'b0, dividend};
    end
		start:
    begin
      if(_signed)
      begin
        //if(dividend[31])  //handle sign bit somehow
      end
      remainder_in << 1'b1;
    end
		subtract:
    begin
      remainder_in[63:32] = remainder_in[63:32] - divisor_in;
    end
		test:
    begin
      if(remainder_in<0)
      begin
        remainder_in[63:32] = remainder_in[63:32] + divisor_in;
        remainder_in << 1'b1;
      end
      else
      begin
        remainder_in << 1'b1;
        remainder_in[0] = 1'b1;
      end
      counter = counter + 1'b1;
    end
		done:
    begin
      remainder_in >> 1'b1;
      done_bit = 1'b1;
    end
	endcase
end

endmodule : divider_control
