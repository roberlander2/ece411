import div_types::*;

module divider
(
    input logic clk_i,
    input logic reset_n_i,
    input operand_t multiplicand_i,
    input operand_t multiplier_i,
    input logic start_i,
    output logic ready_o,
    output result_t product_o,
    output logic done_o
	 output logic error
);

register #(32) divisor (
    .clk(clk),
    .load(set_rdata),
    .in(pmem_rdata),
    .out(latched_rdata)
);

register #(64) remainder (
    .clk(clk),
    .load(set_rdata),
    .in(pmem_rdata),
    .out(latched_rdata)
);


endmodule : divider