import rv32i_types::*;

module l2_go_reg (
    input clk,
    input load,
    input l2_go_t in,
    output l2_go_t out
);

l2_go_t data = 0;

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

endmodule : l2_go_reg