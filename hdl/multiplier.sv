import mult_types::*;

module multiplier
(
    input logic clk_i,
	 input logic signed1,
	 input logic signed2,
    input logic [31:0] multiplicand_i,
    input logic [31:0] multiplier_i,
    input logic start_i,
    output logic ready_o,
    output logic [63:0] product_o,
    output logic done_o
);

/******************************** Declarations *******************************/
mstate_s ms = '{default: '0, ready: 1'b1};
mstate_s ms_init;
mstate_s ms_add_shift;

logic update_state;
logic [63:0] unsigned_prod;
assign unsigned_prod = {ms.A, ms.Q};
logic multiplicand_positive;
assign multiplicand_positive = ~multiplicand_i[31];

logic multiplier_positive;
assign multiplier_positive = ~multiplier_i[31];

/*
*Final Sign is low if both operands are postive or negative
*Therefore, final sign  ==0  means positive result
*/

logic final_sign;
assign final_sign = multiplier_positive ^ multiplicand_positive; 


assign ready_o = ms.ready;
assign done_o = ms.done;
assign product_o = (final_sign && (signed1 || signed2)) ? (~unsigned_prod + 1'b1) : unsigned_prod;

// Describes multiplication initialization state
function void init(input logic[31:0] multiplicand,
                   input logic[31:0] multiplier,
                   output mstate_s ms_next);
						 
    ms_next.ready = 1'b0;
    ms_next.done = 1'b0;
    ms_next.iteration = 0;
    ms_next.op = ADD_SHIFT;

    ms_next.M = (signed1) ? ((multiplicand_positive) ? multiplicand : (~multiplicand + 1)) : multiplicand; 
    ms_next.C = 1'b0;
    ms_next.A = 0;
    ms_next.Q = (signed2) ? ((multiplier_positive) ? multiplier : (~multiplier + 1)) : multiplier; 
endfunction

function void add_shift(input mstate_s cur, output mstate_s next);
		mstate_s inter;
		inter = cur;
	   next.op = ADD_SHIFT;
	   if (cur.Q[0])
	   	  {inter.C, inter.A} = cur.A + cur.M;
	   else
	   	  inter.C = 1'b0;
			  
      next = inter;
      {next.A, next.Q} = {inter.C, inter.A, inter.Q[31:1]};
      next.iteration += 1;
      if (next.iteration == 32) begin
            next.op = DONE;
            next.done = 1'b1;
            next.ready = 1'b1;
      end
endfunction


always_comb begin
    update_state = 1'b0;
    if ((start_i) | (ms.op == ADD_SHIFT))
        update_state = 1'b1;
    init(multiplicand_i, multiplier_i, ms_init);
	 add_shift(ms, ms_add_shift);
end

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i) begin
	 if (update_state) begin
        if (start_i & ready_o) begin
            ms <= ms_init;
        end
        else begin
            case (ms.op)
					 ADD_SHIFT: ms <= ms_add_shift;
                default: ms <= ms_init;
            endcase
        end
    end
end
/*****************************************************************************/


endmodule : multiplier

