module gh_register
(
    input clk,
    input load,
    input logic in,
    output logic [7:0] out
);

logic [7:0] data = 8'b0;

always_ff @(posedge clk)
begin
    if (load)
    begin
		  
        data = {data << 1, in}; //latest branch takes the LSB
    end
end

always_comb
begin
    out = data;
end

endmodule : gh_register
