import rv32i_types::*;

module BTB #(parameter size = 10)(
	input logic clk, 
	input logic [size-1:0] gshare_idx,
	input load,
	input read,
	input rv32i_word wtarget,
	output rv32i_word rtarget
);

logic tag = gshare_idx[9:5];
logic idx = gshare_idx[4:0];

//instantiate data arrays (for target data) 
//and arrays for tag and valid data

endmodule: BTB