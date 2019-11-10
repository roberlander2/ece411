`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)\

import rv32i_types::*;

module datapath
(
	input clk,
	input rv32i_word inst, //inputted from the I-Cache
	input rv32i_word mem_rdata,
	input load_pipeline,
	output logic dwrite,
	output logic iread, 
	output logic dread,
	output rv32i_word mem_address,
	output rv32i_word mem_wdata,
	output rv32i_word inst_addr, //needs to be outputted to the I-Cache
	output logic [3:0] mem_byte_enable,
	output logic stall
);

//loads
logic load_pc;

logic is_jalr;
logic is_jal;
logic is_jalr_mem;
logic is_jal_mem;

//mux outputs
rv32i_word pcmux_out;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmpmux_out;
rv32i_word regfilemux_out;
rv32i_word mem_addressmux_out;

//mux selects
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;

//module outputs
control_word_t cw;
control_word_t cw_mux_out;
rv32i_word alu_out;
logic cmp_out;
logic br_en;
logic br_en_flush;
logic flush;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word pc_out;

//pipeline signals
rv32i_word ifid_pc_out;

rv32i_word idex_pc_out;
rv32i_word idex_rs1_out;
rv32i_word idex_rs2_out;
control_word_t idex_cw;

rv32i_word exmem_pc_out;
rv32i_word exmem_alu_out;
rv32i_word exmem_rs2_out;
rv32i_word exmem_cmp_out;
control_word_t exmem_cw;

rv32i_word memwb_pc_out;
rv32i_word memwb_alu_out;
rv32i_word memwb_cmp_out;
rv32i_word memwb_rs2_out;
control_word_t memwb_cw;
rv32i_word alu_in1;
rv32i_word alu_in2;
rv32i_word cmp_in1;
rv32i_word cmp_in2;
rv32i_word memex_forward;
rv32i_word rs1_in;
rv32i_word rs2_in;
rv32i_word mem_wdata_forward;

logic [1:0] mem_addrmod4;
logic [4:0] mem_addrmod4_mult;
rv32i_word mdrreg_bytemask;
rv32i_word mdrreg_halfmask;

assign mem_addrmod4 = mem_address[1:0];
assign mem_addrmod4_mult = mem_addrmod4 << 3;
assign mdrreg_bytemask = (mem_rdata & (32'h000000FF << mem_addrmod4_mult)) >> mem_addrmod4_mult;
assign mdrreg_halfmask = (mem_rdata & (32'h0000FFFF << mem_addrmod4_mult)) >> mem_addrmod4_mult;

assign inst_addr = pc_out;
assign mem_address = mem_addressmux_out;
assign iread = 1'b1;
assign load_pc = load_pipeline;
assign br_en = ((idex_cw.opcode == op_br) && cmp_out) && ~idex_cw.flush; //execute stage 
assign br_en_flush = ((exmem_cw.opcode == op_br) && exmem_cmp_out) && ~exmem_cw.flush; //memory stage 
assign flush = br_en || br_en_flush || is_jalr || is_jal || is_jalr_mem || is_jal_mem;
assign is_jalr = (idex_cw.opcode == op_jalr) && ~idex_cw.flush;
assign is_jal = (idex_cw.opcode == op_jal) && ~idex_cw.flush;
assign is_jalr_mem = (exmem_cw.opcode == op_jalr) && ~exmem_cw.flush;
assign is_jal_mem = (exmem_cw.opcode == op_jal) && ~exmem_cw.flush;
//use normal pc sel if neither of the two instructions in front is a branch
assign pcmux_sel = pcmux::pcmux_sel_t'({is_jalr, (br_en || is_jal)});

assign mem_byte_enable = exmem_cw.wmask << mem_address[1:0];
assign dread = exmem_cw.mem_read;
assign dwrite = exmem_cw.mem_write;

logic forward_exmem_rs1;
logic forward_memwb_rs1;
logic forward_exmem_rs2;
logic forward_memwb_rs2;
logic forward_memwb_id_rs1;
logic forward_memwb_id_rs2;
logic forward_wb2mem;
logic stall_rs1;
logic stall_rs2;

assign stall = (stall_rs1 || stall_rs2 ) && (idex_cw.opcode == op_load);

forward exmem_rs1 (
	.write(exmem_cw.load_regfile),
	.valid_src(idex_cw.rs1_valid),
	.valid_dest(exmem_cw.rd_valid),
	.src(idex_cw.src1),
	.dest(exmem_cw.dest),
	.fwd(forward_exmem_rs1)
);

forward memwb_rs1 (
	.write(memwb_cw.load_regfile),
	.valid_src(idex_cw.rs1_valid),
	.valid_dest(memwb_cw.rd_valid),
	.src(idex_cw.src1),
	.dest(memwb_cw.dest),
	.fwd(forward_memwb_rs1)
);

forward exmem_rs2(
	.write(exmem_cw.load_regfile),
	.valid_src(idex_cw.rs2_valid),
	.valid_dest(exmem_cw.rd_valid),
	.src(idex_cw.src2),
	.dest(exmem_cw.dest),
	.fwd(forward_exmem_rs2)
);

forward memwb_rs2 (
	.write(memwb_cw.load_regfile),
	.valid_src(idex_cw.rs2_valid),
	.valid_dest(memwb_cw.rd_valid),
	.src(idex_cw.src2),
	.dest(memwb_cw.dest),
	.fwd(forward_memwb_rs2)
);

forward memwb_id_rs1 (
	.write(memwb_cw.load_regfile),
	.valid_src(cw.rs1_valid),
	.valid_dest(memwb_cw.rd_valid),
	.src(cw.src1),
	.dest(memwb_cw.dest),
	.fwd(forward_memwb_id_rs1)
);

forward memwb_id_rs2 (
	.write(memwb_cw.load_regfile),
	.valid_src(cw.rs2_valid),
	.valid_dest(memwb_cw.rd_valid),
	.src(cw.src2),
	.dest(memwb_cw.dest),
	.fwd(forward_memwb_id_rs2)
);

forward wbTomem (
	.write(memwb_cw.load_regfile),
	.valid_src(exmem_cw.rs2_valid),
	.valid_dest(memwb_cw.rd_valid),
	.src(exmem_cw.src2),
	.dest(memwb_cw.dest),
	.fwd(forward_wb2mem)
);

forward stallRS1 (
	.write(idex_cw.load_regfile),
	.valid_src(cw.rs1_valid),
	.valid_dest(idex_cw.rd_valid),
	.src(cw.src1),
	.dest(idex_cw.dest),
	.fwd(stall_rs1)
);

forward stallRS2 (
	.write(idex_cw.load_regfile),
	.valid_src(cw.rs2_valid),
	.valid_dest(idex_cw.rd_valid),
	.src(cw.src2),
	.dest(idex_cw.dest),
	.fwd(stall_rs2)
);

//datapath modules
//fetch
pc PC(
	.clk(clk),
	.load(load_pc && ~stall),
	.in(pcmux_out),
	.out(pc_out)
);

//decode
regfile REGFILE(
	.clk(clk),
	.load(memwb_cw.load_regfile),
	.in(regfilemux_out),
	.src_a(cw.src1),
	.src_b(cw.src2),
	.dest(memwb_cw.dest),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

control CONTROL(
	.data(inst),
	.flush(flush),
	.cw(cw)
);

//execute
alu ALU(
	.aluop(idex_cw.aluop),
	.a(alu_in1),
	.b(alu_in2),
	.f(alu_out)
);

cmp CMP (
	.a(cmp_in1), //idex_rs1_out
	.b(cmp_in2), //cmpmux_out
	.cmpop(idex_cw.cmpop),
	.br_en(cmp_out)
);

//memory
reg_mem_data_out MEM_DATA_OUT(
	.in(mem_wdata_forward),
	.funct3(exmem_cw.funct3),
	.out(mem_wdata)
);

//write back


//Pipeline Registers -use leading <stage>_ to denote pipeline register
//IF/ID
register ifid_PC(
    .clk  (clk),
    .load (load_pipeline && ~stall),
    .in   (pc_out),
    .out  (ifid_pc_out)
);

//ID/EX
register idex_PC(
    .clk  (clk),
    .load (load_pipeline),
    .in   (ifid_pc_out),
    .out  (idex_pc_out)
);

register idex_RS1(
    .clk  (clk),
    .load (load_pipeline),
    .in   (rs1_in),
    .out  (idex_rs1_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_pipeline),
    .in   (rs2_in),
    .out  (idex_rs2_out)
);

cw_register idex_CW(
    .clk  (clk),
    .load (load_pipeline),
    .in   (cw_mux_out),
    .out  (idex_cw)
);

//EX/MEM
register exmem_PC(
    .clk  (clk),
    .load (load_pipeline),
    .in   (idex_pc_out),
    .out  (exmem_pc_out)
);

register exmem_ALU(
    .clk  (clk),
    .load (load_pipeline),
    .in   (alu_out),
    .out  (exmem_alu_out)
);

register exmem_RS2(
    .clk  (clk),
    .load (load_pipeline),
    .in   (idex_rs2_out),
    .out  (exmem_rs2_out)
);

register exmem_CMP(
    .clk  (clk),
    .load (load_pipeline),
    .in   ({31'b0, cmp_out}), //perform ZEXT here?
    .out  (exmem_cmp_out)
);

cw_register exmem_CW(
    .clk  (clk),
    .load (load_pipeline),
    .in   (idex_cw),
    .out  (exmem_cw)
);

//MEM/WB
register memwb_PC(
    .clk  (clk),
    .load (load_pipeline),
    .in   (exmem_pc_out),
    .out  (memwb_pc_out)
);

register memwb_ALU(
    .clk  (clk),
    .load (load_pipeline),
    .in   (exmem_alu_out),
    .out  (memwb_alu_out)
);

register memwb_RS2(
    .clk  (clk),
    .load (load_pipeline),
    .in   (exmem_rs2_out),
    .out  (memwb_rs2_out)
);

register memwb_CMP(
    .clk  (clk),
    .load (load_pipeline),
    .in   (exmem_cmp_out), //perform ZEXT here?
    .out  (memwb_cmp_out)
);

cw_register memwb_CW(
    .clk  (clk),
    .load (load_pipeline),
    .in   (exmem_cw),
    .out  (memwb_cw)
);

//forwarding logic
always_comb begin
	unique case (forward_wb2mem)
		1'b0: mem_wdata_forward = exmem_rs2_out;
		1'b1: mem_wdata_forward = regfilemux_out;
	endcase
	unique case({forward_exmem_rs1, forward_memwb_rs1})
		2'b00: begin
					alu_in1 = alumux1_out;
					cmp_in1 = idex_rs1_out;
				 end
		2'b01: begin
					alu_in1 = regfilemux_out;
					cmp_in1 = regfilemux_out;
				 end
		2'b10: begin
					alu_in1 = memex_forward;
					cmp_in1 = memex_forward;
				 end
		2'b11: begin
					alu_in1 = memex_forward;
					cmp_in1 = memex_forward;
				 end
	endcase
	
	unique case({forward_exmem_rs2, forward_memwb_rs2})
		2'b00: begin
					alu_in2 = alumux2_out;
					cmp_in2 = cmpmux_out;
				 end
		2'b01: begin
					alu_in2 = regfilemux_out;
					cmp_in2 = regfilemux_out;
				 end
		2'b10: begin
					alu_in2 = memex_forward;
					cmp_in2 = memex_forward;
				 end
		2'b11: begin
					alu_in2 = memex_forward;
					cmp_in2 = memex_forward;
				end
	endcase
	
	unique case (exmem_cw.regfilemux_sel)
		regfilemux::alu_out: memex_forward = exmem_alu_out;
		regfilemux::br_en: memex_forward = exmem_cmp_out;
		regfilemux::u_imm: memex_forward = exmem_cw.u_imm;
		regfilemux::pc_plus4: memex_forward = exmem_pc_out + 4;
		default: memex_forward = 32'hXXXXXXXX;
	endcase
	 
	unique case (forward_memwb_id_rs1)
		1'b1: rs1_in = regfilemux_out;
		1'b0: rs1_in = rs1_out;
	endcase
	 
	unique case (forward_memwb_id_rs2)
		1'b1: rs2_in = regfilemux_out;
		1'b0: rs2_in = rs2_out;
	endcase
	 
	unique case (stall)
		1'b0: cw_mux_out = cw;
		1'b1: cw_mux_out = 0;
	endcase
end


always_comb begin	 
	 //fetch
    unique case (pcmux_sel)	
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = alu_out;
		  pcmux::alu_mod2: pcmux_out = alu_out & 32'hFFFFFFFE;
        default: pcmux_out = pc_out + 4;
    endcase
	 	 
	 //execute
	 unique case (idex_cw.alumux1_sel)
		 alumux::rs1_out: alumux1_out = idex_rs1_out;
		 alumux::pc_out: alumux1_out = idex_pc_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (idex_cw.alumux2_sel)
		 alumux::i_imm: alumux2_out = idex_cw.i_imm;
		 alumux::u_imm: alumux2_out = idex_cw.u_imm;
		 alumux::b_imm: alumux2_out = idex_cw.b_imm;
		 alumux::s_imm: alumux2_out = idex_cw.s_imm;
		 alumux::j_imm: alumux2_out = idex_cw.j_imm;
		 alumux::rs2_out: alumux2_out = idex_rs2_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (idex_cw.cmpmux_sel)
		 cmpmux::rs2_out: cmpmux_out = idex_rs2_out;
		 cmpmux::i_imm: cmpmux_out = idex_cw.i_imm;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 //memory
	 unique case (exmem_cw.marmux_sel)
		 marmux::pc_out: mem_addressmux_out = exmem_pc_out;
		 marmux::alu_out: mem_addressmux_out = exmem_alu_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 //write back
	 unique case (memwb_cw.regfilemux_sel)
	 regfilemux::alu_out: regfilemux_out = memwb_alu_out;
	 regfilemux::br_en: regfilemux_out = memwb_cmp_out;
	 regfilemux::u_imm: regfilemux_out = memwb_cw.u_imm;
	 regfilemux::lw: regfilemux_out = mem_rdata;
	 regfilemux::pc_plus4: regfilemux_out = memwb_pc_out + 4;
	 regfilemux::lb: regfilemux_out = mdrreg_bytemask | {{24{mdrreg_bytemask[7]}}, 8'h00};
    regfilemux::lbu: regfilemux_out = mdrreg_bytemask;
    regfilemux::lh: regfilemux_out = mdrreg_halfmask | {{16{mdrreg_halfmask[15]}}, 16'h0000};
    regfilemux::lhu: regfilemux_out = mdrreg_halfmask;
	 default: `BAD_MUX_SEL;
	 endcase
end

endmodule: datapath