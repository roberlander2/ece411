import rv32i_types::*;

module cw_register
(
    input clk,
    input load,
    input control_word_t in,
    output control_word_t out
);

control_word_t data = 1'b0;

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

endmodule : cw_register
