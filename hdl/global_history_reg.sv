module gh_register #(parameter size = 10)
(
    input clk,
    input load,
    input logic in,
    output logic [size-1:0] out
);

logic [size-1:0] data = 0;

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
