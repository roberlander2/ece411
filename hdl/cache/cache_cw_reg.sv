module cache_cw_reg
(
    input clk,
    input load,
    input cache_cw_t in,
    output cache_cw_t out
);

cache_cw_t data = 1'b0;

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

endmodule : cache_cw_reg
