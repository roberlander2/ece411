import div_types::*;

module divider
(
    input logic clk,
    input logic load_divisor,
    input logic load_remainder,
    input divisor_t divisor_in,
    input remainder_t remainder_in,
    output divisor_t divisor_out,
    output remainder_t remainder_out
);

register #(32) divisor (
    .clk(clk),
    .load(load_divisor),
    .in(divisor_in),
    .out(divisor_out)
);

register #(64) remainder (
    .clk(clk),
    .load(load_remainder),
    .in(remainder_in),
    .out(remainder_out)
);

endmodule : divider
