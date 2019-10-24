import rv32i_types::*; /* Import types defined in rv32i_types.sv */
module reg_mem_data_out #(parameter width = 32)
(
    input [width-1:0] in,
	 input logic [2:0] funct3,
    output logic [width-1:0] out
);

store_funct3_t store_funct3;
assign store_funct3 = store_funct3_t'(funct3);

always_comb
begin
	 unique case (store_funct3)
		sh: out = {{2{in[15:0]}}};
		sb: out = {{4{in[7:0]}}};
		default: out = in;
	 endcase
end

endmodule : reg_mem_data_out
