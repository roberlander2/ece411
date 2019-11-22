module pseudo_lru #(
    parameter s_assoc = 8,
    parameter s_width = $clog2(s_assoc),
    parameter s_leaf = (s_assoc/2)-1
)(
	 input clk,
	 input load_lru,
	 input [s_assoc-1:0] way_onehot,
	 output logic [s_width-1:0] way_out,
	 output logic lru_valid
);

logic [s_assoc-2:0] new_lru;
logic [s_assoc-2:0] lru_out;
logic [s_width-1:0] miss_indices [s_width-1:0];
logic [s_width-1:0] miss_index_valid;
logic [s_width-1:0] way_in;
logic [s_width-1:0] way_in_latch;
logic [s_width-1:0] hit_index;
logic [s_width-1:0] hit_index_latch;
logic [s_width-1:0] hit_indices [s_width-1:0];
logic [s_width-1:0] hit_index_valid;

logic hit_last_index_valid;
logic miss_last_index_valid;
logic way_valid;
logic hit;

logic hit_valid;
logic miss_valid;
logic hit_update;
logic miss_update;
logic indices_invalid;
logic [s_assoc-1:0] way_select;

assign miss_indices[0] = 0;
assign hit_indices[0] = hit_index_latch;

assign hit_last_index_valid = hit_index_valid[s_width-1];
assign miss_last_index_valid = miss_index_valid[s_width-1];
assign way_valid = miss_index_valid[s_width-1];
assign hit_index = s_leaf[s_width-1:0] + (way_in >> 1);
assign hit = |(way_onehot);

assign hit_index_valid[0] = hit_valid;
assign miss_index_valid[0] = miss_valid;
assign way_select = {{(s_assoc-1){1'b0}}, 1'b1};

pseudo_lru_control  plru_ctrl(.*);

register #(s_width) hit_index_reg (
   .clk (clk),
   .load (load_lru),
   .in (hit_index),
   .out (hit_index_latch)
);

register #(s_width) way_reg (
   .clk (clk),
   .load (load_lru),
   .in (way_in),
   .out (way_in_latch)
);

way_calc #(s_assoc) lru_way_out (
	.lru_out (lru_out),
	.leaf_index (miss_indices[s_width-1]),
	.way_out (way_out)
);

register #(s_assoc-1) lru_reg (
   .clk (clk),
   .load (hit_update || miss_update),
   .in (new_lru),
   .out (lru_out)
);

lru_index_calc #(s_assoc) index_calculator [s_width-2:0](
	.clk (clk),
	.load(miss_index_valid[s_width-2:0]),
	.invalidate (indices_invalid),
	.parent (miss_indices[s_width-2:0]),
	.lru_out (lru_out),
	.child (miss_indices[s_width-1:1]),
	.child_valid (miss_index_valid[s_width-1:1])
);

lru_hit_index_calc #(s_assoc) hit_index_calculator [s_width-2:0](
	.clk (clk),
	.load(hit_index_valid[s_width-2:0]),
	.invalidate (indices_invalid),
	.child (hit_indices[s_width-2:0]),
	.parent (hit_indices[s_width-1:1]),
	.parent_valid (hit_index_valid[s_width-1:1])
);

lru_update #(s_assoc) lru_updater(
	.clk (clk),
	.indices (miss_indices),
	.hit_indices (hit_indices),
	.lru_out (lru_out),
	.hit_last_index_valid (hit_index_valid[s_width-2] && hit_valid),
	.miss_last_index_valid (miss_index_valid[s_width-2] && miss_valid),
	.way_in (way_in_latch),
	.new_lru (new_lru)
);

always_comb begin
//	unique case (way_onehot)
		way_in = {s_width{1'bX}};
		for (int i = 0; i < s_assoc; i++) begin
			if (way_onehot == way_select << i)
				way_in = i[s_width-1:0];
		end
//		8'h01 : way_in = 3'h0;
//		8'h02 : way_in = 3'h1;
//		8'h04 : way_in = 3'h2;
//		8'h08 : way_in = 3'h3;
//		8'h10 : way_in = 3'h4;
//		8'h20 : way_in = 3'h5;
//		8'h40 : way_in = 3'h6;
//		8'h80 : way_in = 3'h7;
//		default : way_in = 3'bXXX;
//	endcase
end

endmodule : pseudo_lru
