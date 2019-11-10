import rv32i_types::*;

module l2_ret_reg (
    input clk,
    input load,
    input l2_ret_t in,
    output l2_ret_t out
);

l2_ret_t data = 0;

always_ff @(posedge clk)
begin
    if (load)
    begin
        data = in;
    end
end

always_comb
begin
    out = data;
end

endmodule : l2_ret_reg