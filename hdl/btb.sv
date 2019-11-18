import rv32i_types::*;
/*
*A direct mapped implementation of a
*Branch Target Buffer designed to store  --index BTB based on PC
*/
module BTB #(parameter size = 32)(
	input logic clk, 
	input logic [size-1:0] rPC,
	input logic [size-1:0] wPC,
	input load,
	input read,
	input rv32i_word wtarget,
	output rv32i_word rtarget,
	output logic btb_hit
);
localparam idx_size = 6;
localparam num_sets = 2 ** idx_size;
localparam tag_size = size - 6;

logic [size-1: idx_size] rtag;
logic [size-1: idx_size] wtag;
logic [idx_size-1:0] ridx;
logic [idx_size-1:0] widx; 
rv32i_word tar_out;
logic [tag_size-1: 0] tag_out;
logic valid_out;

assign rtag = rPC[size-1:idx_size];
assign wtag = wPC[size-1:idx_size];
assign ridx = rPC[idx_size-1:0]; //64 entries in the BTB
assign widx = wPC[idx_size-1:0]; 


assign btb_hit = (tag_out == rPC[size-1:idx_size]) && valid_out;
assign rtarget = tar_out;


//instantiate data arrays (for target data) 
//and arrays for tag and valid data

array #(idx_size, tag_size) tags(
	 .clk(clk),
    .read(read),
    .load(load),
    .rindex(ridx),
    .windex(widx),
    .datain(wtag),
    .dataout(tar_out)
);

array #(idx_size, 32) targets (
	 .clk(clk),
    .read(read),
    .load(load),
    .rindex(ridx),
    .windex(widx),
    .datain(wtarget),
    .dataout(tag_out)
);

array #(idx_size, 1) valid_tar (
	 .clk(clk),
    .read(read),
    .load(load),
    .rindex(ridx),
    .windex(widx),
    .datain(1'b1),
    .dataout(valid_out)
);



endmodule: BTB