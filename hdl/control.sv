import rv32i_types::*;

typedef struct packed {
	rv32i_opcode op;
	logic [4:0] src1;
	logic [4:0] src2;
	logic [4:0] dest;
	//add all other relevant signals 
} control_word_t;

module control (
	input clk,
	input rv32i_word inst,
	output control_word_t control_word
);


endmodule: control