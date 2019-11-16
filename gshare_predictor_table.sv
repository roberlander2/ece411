module gshare_table
(
    clk,
    read,
    load,
    rindex,
    windex,
    resolution,
    prediction
);

localparam num_sets = 2 ** 10;
localparam gshare_bits = 10;

input clk;
input read; //if ifid_opcode ==  op_br, op_jal, op_jalr
input load; //if idex_opcode ==  op_br, op_jal, or op_jalr
input [gshare_bits-1:0] rindex; //PC of decode XOR  ifid_GHR
input [gshare_bits-1:0] windex; //PC of execute XOR idex_GHR
input resolution; //from the execute stage, gave a correct prediction==1, else == 0
output logic prediction; //to the decode stage

logic [1:0] data [num_sets-1:0] = '{default: '0};
logic _final_prediction;
logic _prediction;
logic _update;
assign prediction = _final_prediction;

always_comb begin

	if(read) begin
		unique case(data[rindex])
			2'b00: _prediction = 0;
			2'b01: _prediction = 0;
			2'b10: _prediction = 1;
			2'b11: _prediction = 1;
		endcase
	end 
	
	if(load) begin
		unique case(resolution)
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
	end
	
end

always_ff @(posedge clk)
begin
    if (read)
        _final_prediction <= (load  & (rindex == windex)) ? resolution : _prediction;

    if(load) // based on the resolution, update the counter in the table
        data[windex] <= _update;
end
endmodule : gshare_table

