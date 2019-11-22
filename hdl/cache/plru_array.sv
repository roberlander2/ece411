module plru_array #(
	parameter s_index = 3,
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)
(
    clk,
    read,
    load,
    index,
    tag_hit,
    dataout,
	 valid
);

localparam num_sets = 2**s_index;

input clk;
input read;
input load;
input [s_index-1:0] index;
input [s_assoc-1:0] tag_hit;
output logic [s_width-1:0] dataout;
output logic valid;

logic [num_sets-1:0] lru_valid;
logic [num_sets-1:0] load_plru = 0;
logic [s_width-1:0] data [num_sets-1:0];

pseudo_lru #(s_assoc) plru [num_sets-1:0] (
	 .clk(clk),
	 .load_lru (load_plru),
	 .way_onehot (tag_hit),
	 .way_out (data),
	 .lru_valid (lru_valid)
);

always_ff @(posedge clk)
begin
    if (read) begin
		  dataout <= data[index];
		  valid <= lru_valid[index];
	 end
end

always_comb begin
	if (load)
		load_plru = {{(s_assoc-1){1'b0}}, 1'b1} << index;
	else
		load_plru = 0;
end

endmodule : plru_array