
module btb_array #(
	parameter s_index = 3,
	parameter width = 1
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

localparam num_sets = 2**s_index;

input clk;
input read;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] = '{default: '0};
logic [width-1:0] _dataout;
assign dataout = _dataout;

/* Initialize array */
//initial
//begin
//    for (int i = 0; i < num_sets; i++)
//    begin
//        data[i] = 1'b0;
//    end
//end
always_comb begin
	unique case(read)
		1'b0: _dataout = {width{1'bX}};
		1'b1: _dataout = (load  & (rindex == windex)) ? datain : data[rindex];
	endcase
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : btb_array

