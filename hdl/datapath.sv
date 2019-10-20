`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)\

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
assign load_piperegs = 1'b1; //always high??
logic load_pc;

//mux outputs
logic pcmux_out;

//mux selects
logic pcmux::pcmux_sel_t pcmux_sel;

//module outputs
rv32i_word pc_out;
rv32i_word cw;
rv32i_word alu_out;
logic cmp_out;

//pipeline signals
rv32i_word ifid_pc_out;

rv32i_wrod idex_pc_out;
rv32i_word idex_rs1_out;
rv32i_word idex_rs2_out;
control_word_t idex_cw;

rv32i_wrod exmem_pc_out;
rv32i_word exmem_alu_out;
rv32i_word exmem_rs2_out;
rv32i_word exmem_cmp_out;
control_word_t exmem_cw;

rv32i_wrod memwb_pc_out;
rv32i_word memwb_alu_out;
rv32i_word memwb_cmp_out;
control_word_t memwb_cw;

//datapath modules
//fetch
pc PC(
	.clk(clk),
	.load(load_pc),
	.in(pcmux_out),
	.out(pc_out)
);

//decode
regfile REGFILE(
	.clk(clk),
	.load(cw.load_regfile),
	.in(regfilemux_out),
	.src_a(cw.src1),
	.src_b(cw.src2),
	.dest(cw.dest),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

control CONTROL(
	.clk(clk),
	.inst(inst),
	.cw(cw)
);

//execute
alu ALU(
	.aluop(aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

cmp CMP (
	.a(idex.rs1_out),
	.b(cmpmux_out),
	.cmpop(cmpop),
	.br_en(cmp_out)
);

//Pipeline Registers -use leading <stage>_ to denote pipeline register
//IF/ID
register ifid_PC(
    .clk  (clk),
    .load (load_piperegs),
    .in   (pc_out),
    .out  (ifid_pc_out)
);

//ID/EX
register idex_PC(
    .clk  (clk),
    .load (load_piperegs),
    .in   (ifid_pc_out),
    .out  (idex_pc_out)
);

register idex_RS1(
    .clk  (clk),
    .load (load_piperegs),
    .in   (rs1_out),
    .out  (idex_rs1_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_piperegs),
    .in   (rs2_out),
    .out  (idex_rs2_out)
);

register idex_CW(
    .clk  (clk),
    .load (load_piperegs),
    .in   (cw),
    .out  (idex_cw)
);

//EX/MEM
register idex_PC(
    .clk  (clk),
    .load (load_piperegs),
    .in   (idex_pc_out),
    .out  (exmem_pc_out)
);

register exmem_ALU(
    .clk  (clk),
    .load (load_piperegs),
    .in   (alu_out),
    .out  (exmem_alu_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_piperegs),
    .in   (idex_rs2_out),
    .out  (exmem_rs2_out)
);

register exmem_CMP(
    .clk  (clk),
    .load (load_piperegs),
    .in   ({31'b0, cmp_out}),
    .out  (exmem_cmp_out)
);

register idex_CW(
    .clk  (clk),
    .load (load_piperegs),
    .in   (idex_cw),
    .out  (exmem_cw)
);

//MEM/WB
register idex_PC(
    .clk  (clk),
    .load (load_piperegs),
    .in   (exmem_pc_out),
    .out  (memwb_pc_out)
);

register exmem_ALU(
    .clk  (clk),
    .load (load_piperegs),
    .in   (exmem_alu_out),
    .out  (memwb_alu_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_piperegs),
    .in   (exmem_rs2_out),
    .out  (memwb_rs2_out)
);

register idex_CW(
    .clk  (clk),
    .load (load_piperegs),
    .in   (exmem_cw),
    .out  (memwb_cw)
);

assign br_en = (cw.opcode == op_br) && cmp_out //execute stage
always_comb begin : MUXES
	 //fetch
    unique case (cw.pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = alu_out;
		  pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
        default: `BAD_MUX_SEL;
    endcase
	 	 
	 //execute
	 unique case (cw.alumux1_sel)
		 alumux::rs1_out: alumux1_out = idex_rs1_out;
		 alumux::pc_out: alumux1_out = idex_pc_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (cw.alumux2_sel)
		 alumux::i_imm: alumux2_out = idex.cw.i_imm;
		 alumux::u_imm: alumux2_out = idex.cw.u_imm;
		 alumux::b_imm: alumux2_out = idex.cw.b_imm;
		 alumux::s_imm: alumux2_out = idex.cw.s_imm;
		 alumux::j_imm: alumux2_out = idex.cw.j_imm;
		 alumux::rs2_out: alumux2_out = idex.rs2_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (cw.cmpmux_sel)
		 cmpmux::rs2_out: cmpmux_out = idex.rs2_out;
		 cmpmux::i_imm: cmpmux_out = idex.cw.i_imm;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 //mem
end

endmodule: datapath