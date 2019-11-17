import rv32i_types::*;
/*
*A direct mapped implementation of a
*Branch Target Buffer designed to store 
*/
module BTB #(parameter size = 10)(
	input logic clk, 
	input logic [size-1:0] gshare_idx,
	input load,
	input read,
	input rv32i_word wtarget,
	output rv32i_word rtarget
);
localparam num_sets = 2 ** 10;
localparam tag_bits = 5;
localparam idx_bits = 5;
logic tag = gshare_idx[9:5];
logic idx = gshare_idx[4:0];

//instantiate data arrays (for target data) 
//and arrays for tag and valid data

//array tags #(idx_bits, tag_bits) (
//	 clk(),
//    read(),
//    load(),
//    rindex(),
//    windex(),
//    datain(),
//    dataout()
//);
//
//array targets #(idx_bits, tag_bits) (
//	 clk(),
//    read(),
//    load(),
//    rindex(),
//    windex(),
//    datain(),
//    dataout()
//);


endmodule: BTB