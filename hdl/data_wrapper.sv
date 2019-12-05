module data_wrapper #(
    parameter s_index = 3,
    parameter s_offset = 5
)
(
    clk,
    read,
	 load,
    rindex,
    windex,
    datain,
    dataout
);

localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

input clk;
input read;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [s_line-1:0] datain;
output logic [s_line-1:0] dataout;

l2_data l2_bram (
	.clock (clk),
	.data (datain),
	.rdaddress ({rindex, 5'b0}),
	.wraddress ({windex, 5'b0}),
	.wren (load),
	.q (dataout)
);

endmodule : data_wrapper