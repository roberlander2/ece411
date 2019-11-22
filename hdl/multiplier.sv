import mult_types::*;

module add_shift_multiplier
(
    input logic clk_i,
    input logic reset_n_i,
    input operand_t multiplicand_i,
    input operand_t multiplier_i,
    input logic start_i,
    output logic ready_o,
    output result_t product_o,
    output logic done_o
);

/******************************** Declarations *******************************/
mstate_s ms;
mstate_s ms_reset;
mstate_s ms_init;
mstate_s ms_add;
mstate_s ms_shift;
logic update_state;
logic unsigned_prod = {ms.A, ms.Q};
logic multiplicand_sign ;
assign multiplicand_sign  = (multiplicand_i >= 0);

logic multiplier_sign ;
assign multiplier_sign  = (multiplier_i >= 0);

logic final_sign;
assign final_sign = multiplier_sign ^ multiplicand_sign;


assign ready_o = ms.ready;
assign done_o = ms.done;
assign product_o = (final_sign) ? (~unsigned_prod + 1'b1) : unsigned_prod;

// Describes reset state
function void reset(output mstate_s ms_next);
    ms_next = 0;
    ms_next.ready = 1'b1;
endfunction

// Describes multiplication initialization state
function void init(input logic[width_p-1:0] multiplicand,
                   input logic[width_p-1:0] multiplier,
                   output mstate_s ms_next);
						 
    ms_next.ready = 1'b0;
    ms_next.done = 1'b0;
    ms_next.iteration = 0;
    ms_next.op = ADD;

    ms_next.M = (multiplicand >= 0) ? multiplicand : (~(multiplicand) + 1'b1);
    ms_next.C = 1'b0;
    ms_next.A = 0;
    ms_next.Q = (multiplier >= 0) ? multiplier : (~(multiplier) + 1'b1);
endfunction

// Describes state after add occurs
function void add(input mstate_s cur, output mstate_s next);
    next = cur;
    next.op = SHIFT;
    if (cur.Q[0])
        {next.C, next.A} = cur.A + cur.M;
    else
        next.C = 1'b0;
endfunction

// Describes state after shift occurs
function void shift(input mstate_s cur, output mstate_s next);
      next = cur;
      {next.A, next.Q} = {cur.C, cur.A, cur.Q[width_p-1:1]};
      next.op = ADD;
      next.iteration += 1;
      if (next.iteration == width_p) begin
            next.op = DONE;
            next.done = 1'b1;
            next.ready = 1'b1;
      end
endfunction


always_comb begin
    update_state = 1'b0;
    if ((~reset_n_i) | (start_i) | (ms.op == ADD) || (ms.op == SHIFT))
        update_state = 1'b1;
    reset(ms_reset);
    init(multiplicand_i, multiplier_i, ms_init);
    add(ms, ms_add);
    shift(ms, ms_shift);
end

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i) begin
    if (~reset_n_i)
            ms <= ms_reset;
    else if (update_state) begin
        if (start_i & ready_o) begin
            ms <= ms_init;
        end
        else begin
            case (ms.op)
                ADD: ms <= ms_add;
                SHIFT: ms <= ms_shift;
                default: ms <= ms_reset;
            endcase
        end
    end
end
/*****************************************************************************/


endmodule : add_shift_multiplier

