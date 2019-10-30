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
	output logic [3:0] mem_byte_enable
);

//loads
logic load_pc;

logic is_jalr;
logic is_jal;

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
rv32i_word alu_out;
logic cmp_out;
logic br_en;
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

assign inst_addr = pc_out;
assign mem_address = mem_addressmux_out;
assign iread = 1'b1;
assign load_pc = 1'b1;
assign br_en = (idex_cw.opcode == op_br) && cmp_out; //execute stage 
assign is_jalr = (idex_cw.opcode == op_jalr) && 1'b1;
assign is_jal = (idex_cw.opcode == op_jal) && 1'b1;
assign pcmux_sel = pcmux::pcmux_sel_t'({is_jalr, (br_en || is_jal)});

assign mem_byte_enable = exmem_cw.wmask << mem_address[1:0];
assign dread = exmem_cw.mem_read;
assign dwrite = exmem_cw.mem_write;

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
	.cw(cw)
);

//execute
alu ALU(
	.aluop(idex_cw.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

cmp CMP (
	.a(idex_rs1_out),
	.b(cmpmux_out),
	.cmpop(idex_cw.cmpop),
	.br_en(cmp_out)
);

//memory
reg_mem_data_out MEM_DATA_OUT(
	.in(exmem_rs2_out),
	.funct3(exmem_cw.funct3),
	.out(mem_wdata)
);

//write back





//Pipeline Registers -use leading <stage>_ to denote pipeline register
//IF/ID
register ifid_PC(
    .clk  (clk),
    .load (load_pipeline),
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
    .in   (rs1_out),
    .out  (idex_rs1_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_pipeline),
    .in   (rs2_out),
    .out  (idex_rs2_out)
);

cw_register idex_CW(
    .clk  (clk),
    .load (load_pipeline),
    .in   (cw),
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

always_comb begin	 
	 //fetch
    unique case (pcmux_sel)	
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
		  pcmux::alu_out: pcmux_out = alu_out;
		  pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
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
    regfilemux::lb:  begin
								unique case(mem_address[1:0])
									2'b00: regfilemux_out = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
									2'b01: regfilemux_out = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
									2'b10: regfilemux_out = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
									2'b11: regfilemux_out = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
								endcase
							end
	 regfilemux::lbu: begin
								unique case(mem_address[1:0])
									2'b00: regfilemux_out = {24'b0, mem_rdata[7:0]};
									2'b01: regfilemux_out = {24'b0, mem_rdata[15:8]};
									2'b10: regfilemux_out = {24'b0, mem_rdata[23:16]};
									2'b11: regfilemux_out = {24'b0, mem_rdata[31:24]};
								endcase
							end
    regfilemux::lh: begin
							  unique case(mem_address[1:0])
									2'b00: regfilemux_out = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
									2'b01: regfilemux_out = {{16{mem_rdata[23]}}, mem_rdata[23:8]};
									2'b10: regfilemux_out = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
									2'b11: regfilemux_out = {24'b0, mem_rdata[31:24]};
								endcase
						  end
    regfilemux::lhu: begin
							  unique case(mem_address[1:0])
									2'b00: regfilemux_out = {16'b0, mem_rdata[15:0]};
									2'b01: regfilemux_out = {16'b0, mem_rdata[23:8]};
									2'b10: regfilemux_out = {16'b0, mem_rdata[31:16]};
									2'b11: regfilemux_out = {24'b0, mem_rdata[31:24]};
								endcase
						  end
	 default: `BAD_MUX_SEL;
	 endcase
	 
end

endmodule: datapath