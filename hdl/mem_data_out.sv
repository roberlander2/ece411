import rv32i_types::*; /* Import types defined in rv32i_types.sv */
module reg_mem_data_out #(parameter width = 32)
(
    input clk,
    input load,
    input [width-1:0] in,
	 input logic [2:0] funct3,
    output logic [width-1:0] out
);

logic [width-1:0] data = 1'b0;
store_funct3_t store_funct3;
assign store_funct3 = store_funct3_t'(funct3);

always_ff @(posedge clk)
begin
    if (load)
    begin
        data = in;
    end
end

always_comb
begin
	 unique case (store_funct3)
		sh: out = {{2{data[15:0]}}};
		sb: out = {{4{data[7:0]}}};
		default: out = data;
	 endcase
end

endmodule : reg_mem_data_out
