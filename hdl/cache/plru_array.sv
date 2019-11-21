module plru_array #(
	parameter s_index = 3,
	parameter s_assoc = 8,
   parameter s_width = $clog2(s_assoc)
)
(
    clk,
    read,
    load,
    rindex,
    windex,
    tag_hit,
    dataout,
	 valid
);

localparam num_sets = 2**s_index;

input clk;
input read;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [s_assoc-1:0] tag_hit;
output logic [s_width-1:0] dataout;
output logic valid;

logic [num_sets-1:0] lru_valid;
logic [num_sets-1:0] load_plru;
logic [s_width-1:0] data [num_sets-1:0] = '{default: '0};

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
		  dataout <= data[rindex];
		  valid <= lru_valid[rindex];
	 end

    if (load)
        load_plru[windex] <= 1'b1;
end



endmodule : plru_array