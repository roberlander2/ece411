import rv32i_types::*;

/*
*Forward module based on the module described in the "Modified SP19 ECE411 MP3 Lecture" ppt posted to the _tutorials
*branch on the ece 411 github page
*/

module forward (
	input logic write,
	input logic valid_src,
	input logic valid_dest,
	input logic [4:0] src,
	input logic [4:0] dest,
	output logic fwd
);

assign fwd = write & valid_src & valid_dest & (|src) & (|dest) & (src == dest);
		
endmodule: forward
