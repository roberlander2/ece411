module gshare_table #(parameter index = 10)
(
    clk,
    read,
    load,
    rindex,
    windex,
    resolution,
    prediction
);

localparam num_sets = 2 ** index;

input clk;
input read; //if ifid_opcode ==  op_br, op_jal, op_jalr
input load; //if idex_opcode ==  op_br, op_jal, or op_jalr
input [index-1:0] rindex; //PC of decode XOR  ifid_GHR
input [index-1:0] windex; //PC of execute XOR idex_GHR
input resolution; //from the execute stage, gave a correct prediction==1, else == 0
output logic prediction; //to the decode stage

logic [1:0] data [num_sets-1:0] = '{default: '0};
logic rw_simul;
assign rw_simul = load && (rindex == windex);
logic [1:0] _update;
//assign prediction = _final_prediction;

always_comb begin
	
	unique case(rw_simul)
		1'b0: unique case(read)
					1'b0: prediction = 0;
					1'b1: unique case(data[rindex])
								2'b00: prediction = 0;
								2'b01: prediction = 0;
								2'b10: prediction = 1;
								2'b11: prediction = 1;
							endcase
				endcase
		1'b1: prediction = resolution;
	endcase
	
	unique case(load)
		1'b0: _update = 2'b00;	//This doesnt matter, just used to satisfy inferred latch
		1'b1: unique case(resolution)
					1'b0: unique case(data[windex])
								2'b00: _update = 2'b00;
								2'b01: _update = 2'b00;
								2'b10: _update = 2'b01;
								2'b11: _update = 2'b10;
							endcase
					1'b1: unique case(data[windex])
								2'b00: _update = 2'b01;
								2'b01: _update = 2'b10;
								2'b10: _update = 2'b11;
								2'b11: _update = 2'b11;
							endcase
				endcase
	endcase	
end

always_ff @(posedge clk)
begin
    if(load) // based on the resolution, update the counter in the table
        data[windex] <= _update;
end
endmodule : gshare_table

