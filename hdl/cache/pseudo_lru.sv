module pseudo_lru #(
    parameter s_assoc = 8,
    parameter s_width = $clog2(s_assoc),
    parameter s_leaf = (s_assoc/2)-1
)(
	 input clk,
	 input load_lru,
	 input hit,
	 input [s_assoc-1:0] way_onehot,
	 output logic [s_width-1:0] way_out,
	 output logic valid
);

//clk,
//read,
//load,
//rindex,
//windex,
//datain,
//dataout

logic [s_assoc-2:0] new_lru;
logic [s_assoc-2:0] lru_out;
logic [s_width-1:0] indices [s_width-1:0];
logic [s_width-1:0] index_valid;
logic [s_width-1:0] way_in;
logic [s_width-1:0] hit_index;
logic [s_width-1:0] hit_indices [s_width-1:0];
logic [s_width-1:0] hit_index_valid;
logic hit_update;
logic update_lru;

assign indices[0] = 0;
assign valid = index_valid[s_width-1];
assign hit_index = s_leaf[s_width-1:0] + (way_in >> 1);
assign hit_indices[0] = hit_index;
assign hit_index_valid[0] = hit;

way_calc #(s_assoc) lru_way_out (
	.lru_out (lru_out),
	.leaf_index (indices[s_width-1]),
	.way_out (way_out)
);

register #(s_assoc-1) lru_reg (
   .clk (clk),
   .load (update_lru),
   .in (new_lru),
   .out (lru_out)
);

lru_index_calc #(s_assoc) index_calculator [s_width-2:0](
	.clk (clk),
	.load(index_valid[s_width-2:0]),
	.load_lru (load_lru),
	.parent (indices[s_width-2:0]),
	.lru_out (lru_out),
	.child (indices[s_width-1:1]),
	.child_valid (index_valid[s_width-1:1])
);

lru_hit_index_calc #(s_assoc) hit_index_calculator [s_width-2:0](
	.clk (clk),
	.load(hit_index_valid[s_width-2:0]),
	.hit_load_lru (hit && load_lru),
	.child (hit_indices[s_width-2:0]),
	.parent (hit_indices[s_width-1:1]),
	.parent_valid (hit_index_valid[s_width-1:1])
);

lru_update #(s_assoc) lru_updater(
	.clk (clk),
	.hit (hit),
	.indices (indices),
	.hit_indices (hit_indices),
	.lru_out (lru_out),
	.valid (&(index_valid)),
	.hit_valid (hit_index_valid),
	.way_in (way_in),
	.new_lru (new_lru),
	.hit_update (hit_update),
	.set_index_valid(index_valid[0])
);

always_ff @(posedge clk) begin
	if (hit_update)
		
end

always_comb begin
	unique case (way_onehot)
		8'h01 : way_in = 3'h0;
		8'h02 : way_in = 3'h1;
		8'h04 : way_in = 3'h2;
		8'h08 : way_in = 3'h3;
		8'h10 : way_in = 3'h4;
		8'h20 : way_in = 3'h5;
		8'h40 : way_in = 3'h6;
		8'h80 : way_in = 3'h7;
		default : way_in = 3'bXXX;
	endcase
	
	unique case (hit_index_valid[0])
		1'b0 : update_lru = load_lru;
		1'b1 : update_lru = hit_update;
		default : update_lru = load_lru;
	endcase
end

endmodule : pseudo_lru
