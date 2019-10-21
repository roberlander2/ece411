import rv32i_types::*;
/*Simply perform the state actions 
described by the state diagram in MP1.
Determine state by observing the opcode of the given instruction.
*/
module control (
	input clk,
	input rv32i_word inst,
	output control_word_t cw
);

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	cw.load_regfile = 1'b1;
	cw.regfilemux_sel = sel;
endfunction

function void loadDATAOUT();
	cw.load_data_out = 1'b1;
endfunction

function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
	 cw.alumux1_sel = sel1;
	 cw.alumux2_sel = sel2;
    if (setop)
      cw.aluop = op;
	 else
		cw.aluop = op_imm;
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
	cw.cmpmux_sel = sel;
	cw.cmpop = op;
endfunction



assign cw.opcode = rv32i_opcode'(inst[6:0]);
assign cw.funct3 = inst[14:12];
assign cw.funct7 = inst[31:25];

assign cw.i_imm = {{21{inst[31]}}, inst[30:20]};
assign cw.s_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign cw.b_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign cw.u_imm = {inst[31:12], 12'h000};
assign cw.j_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

assign cw.src1 = inst[19:15];
assign cw.src2 = inst[24:20];
assign cw.dest = inst[11:7];
always_comb begin : opcode_actions
	cw.wmask = '0;
	unique case(cw.opcode)
		op_lui: begin
					loadRegfile(regfilemux::u_imm);
				 end
		op_auipc: begin
						loadRegfile(regfilemux::alu_out);
						setALU(alumux::pc_out, alumux::u_imm, 1'b1);
					end
		op_jal: begin
					loadRegfile(regfilemux::pc_plus4);
					setALU(alumux::pc_out, alumux::j_imm, 1'b1);
				 end
		op_jalr: begin
					loadRegfile(regfilemux::pc_plus4);
					setALU(alumux::rs1_out, alumux::i_imm, 1'b1);
				  end
		op_br:  begin
					setALU(alumux::pc_out, alumux::b_imm, 1'b1);
					setCMP(cmpmux::rs2_out, branch_funct3_t'(cw.funct3));
				  end
		op_load: begin
						loadMAR(marmux::alu_out);
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1);
						unique case(load_funct3_t'(cw.funct3))
						lb: loadRegfile(regfilemux::lb);
						lh: loadRegfile(regfilemux::lh);
						lw: loadRegfile(regfilemux::lw);
						lbu:loadRegfile(regfilemux::lbu);
						lhu:loadRegfile(regfilemux::lhu);
					endcase
					end
		op_store: begin
						loadMAR(marmux::alu_out);
						setALU(alumux::rs1_out, alumux::s_imm, 1'b1);
						loadDATAOUT();
						cw.mem_write = 1'b1;
						unique case (store_funct3_t'(cw.funct3))
							sw: cw.wmask = 4'b1111;
							sh: cw.wmask = 4'b0011;
							sb: cw.wmask = 4'b0001;
						endcase
					 end
		op_imm: begin 
						loadRegfile(regfilemux::alu_out);
						unique case(arith_funct3_t'(cw.funct3))
							add: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
								  end
							sll: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sll); 
								  end
							slt: 
								begin
									loadRegfile(regfilemux::br_en);
									setCMP(cmpmux::i_imm, blt);
								end
							sltu:
								begin
									cw.regfilemux_sel = regfilemux::br_en;
									setCMP(cmpmux::i_imm, bltu);
								end
							axor: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_xor); 
								  end
							sr: begin
									loadRegfile(regfilemux::alu_out);
									unique case(cw.funct7)
										7'b0000000: setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
										7'b0100000: setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
										default: ;
									endcase
								 end
							aor: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_or);
								  end
							aand: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_and);
								  end
						endcase
					 end
		op_reg: begin 
						loadRegfile(regfilemux::alu_out);
						unique case(arith_funct3_t'(cw.funct3))
							add: begin
									  loadRegfile(regfilemux::alu_out);
									  unique case(cw.funct7)
										7'b0000000: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
										7'b0100000: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
										default: ;
									  endcase 
								  end
							sll: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sll); 
								  end
							slt: 
								begin
									loadRegfile(regfilemux::br_en);
									setCMP(cmpmux::rs2_out, blt);
								end
							sltu:
								begin
									cw.regfilemux_sel = regfilemux::br_en;
									setCMP(cmpmux::rs2_out, bltu);
								end
							axor: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_xor); 
								  end
							sr: begin
									loadRegfile(regfilemux::alu_out);
									unique case(cw.funct7)
										7'b0000000: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
										7'b0100000: setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
										default: ;
									endcase
								 end
							aor: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_or); 
								  end
							aand: begin
									  loadRegfile(regfilemux::alu_out);
									  setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_and); 
								  end
					endcase
			end 
	 endcase
end 

endmodule: control