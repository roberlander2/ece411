import rv32i_types::*;

module datapath
(
	input clk,
	input iresp,
	input dresp,
	input rv32i_word inst, //inputted from the I-Cache
	input rv32i_word mem_rdata,
	output rv32i_word mem_address,
	output rv32i_word mem_wdata,
	output rv32i_word pc_out //needs to be outputted to the I-Cache
);
//loads
assign load_piperegs = 1'b1;
logic load_pc;

//mux outputs
logic pcmux_out;

//mux selects
logic pcmux::pcmux_sel_t pcmux_sel;

//module outputs
logic pc_out;

//datapath modules
pc PC(
	.clk(clk),
	.load(load_pc),
	.in(pcmux_out),
	.out(pc_out)
);

regfile REGFILE(
	.clk(clk),
	.load(load_regfile),
	.in(regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);


control CONTROL(
	.clk(clk)
);

//Pipeline Registers -use leading <stage>_ to denote pipeline register
//IF/ID
register ifid_PC(
    .clk  (clk),
    .load (load_piperegs),
    .in   (pc_out),
    .out  (ifid_pc_out)
);


always_comb begin : MUXES
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = alu_output;
		  pcmux::alu_mod2: pcmux_out = {alu_output[31:1], 1'b0};
        default: `BAD_MUX_SEL;
    endcase
end

endmodule: datapath