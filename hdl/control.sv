import rv32i_types::*;
/*Simply perform the state actions 
described by the state diagram in MP1.
Determine state by observing the opcode of the given instruction.
*/
module control (
	input rv32i_word data,
	input flush,
	output control_word_t cw
);

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	if(~flush) begin
		cw.load_regfile = 1'b1;
		cw.regfilemux_sel = sel;
	end
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
	cw.marmux_sel = sel;
endfunction

function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
	 cw.alumux1_sel = sel1;
	 cw.alumux2_sel = sel2;
    if (setop)
      cw.aluop = op;
endfunction

function void setMUL(logic signed1, logic signed2, logic half_sel);
	cw.signed1 = signed1;
	cw.signed2 = signed2;
	cw.half_sel = half_sel;
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
	cw.cmpmux_sel = sel;
	cw.cmpop = op;
endfunction

function void setRS1valid();
	cw.rs1_valid = 1'b1;
endfunction

function void setRS2valid();
	cw.rs2_valid = 1'b1;
endfunction

function void setRDvalid();
	cw.rd_valid = 1'b1;
endfunction

function void set_defaults();
	cw.aluop = alu_add;
	cw.cmpop = beq;
	cw.alumux1_sel = alumux::rs1_out;
	cw.alumux2_sel = alumux::i_imm;
	cw.cmpmux_sel = cmpmux::rs2_out;
	cw.regfilemux_sel = regfilemux::alu_out;
	cw.marmux_sel = marmux::pc_out;
	cw.load_regfile = 1'b0;
	cw.mem_read = 1'b0;
	cw.mem_write = 1'b0;
	cw.wmask = 4'b0;
	cw.rs1_valid = 1'b0;
	cw.rs2_valid = 1'b0;
	cw.rd_valid = 1'b0;
	cw.flush = 1'b0;
	cw.signed1 = 1'b0;
	cw.signed2 = 1'b0;
	cw.half_sel = 1'b0;
endfunction

always_comb begin : opcode_actions
	cw.opcode = rv32i_opcode'(data[6:0]);
	cw.funct3 = data[14:12];
	cw.funct7 = data[31:25];
	
	cw.i_imm = {{21{data[31]}}, data[30:20]};
	cw.s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
	cw.b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
	cw.u_imm = {data[31:12], 12'h000};
	cw.j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
	
	cw.src1 = data[19:15];
	cw.src2 = data[24:20];
	cw.dest = data[11:7];
	
	set_defaults();
	cw.flush = flush;
	
	unique case(cw.opcode)
		op_lui: begin
					loadRegfile(regfilemux::u_imm);
					setRDvalid();
				 end
		op_auipc: begin
						loadRegfile(regfilemux::alu_out);
						setALU(alumux::pc_out, alumux::u_imm, 1'b1);
						setRDvalid();
					end
		op_jal: begin
					loadRegfile(regfilemux::pc_plus4);
					setALU(alumux::pc_out, alumux::j_imm, 1'b1);
					setRDvalid();
				 end
		op_jalr: begin
					loadRegfile(regfilemux::pc_plus4);
					setALU(alumux::rs1_out, alumux::i_imm, 1'b1);
					setRDvalid();
					setRS1valid();
				  end
		op_br:  begin
					setALU(alumux::pc_out, alumux::b_imm, 1'b1);
					setCMP(cmpmux::rs2_out, branch_funct3_t'(cw.funct3));
					setRS1valid();
					setRS2valid();
				  end
		op_load: begin
						loadMAR(marmux::alu_out);
						if(~flush) cw.mem_read = 1'b1;
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1);
						setRDvalid();
						setRS1valid();
						unique case(load_funct3_t'(cw.funct3))
							lb: loadRegfile(regfilemux::lb);
							lh: loadRegfile(regfilemux::lh);
							lw: loadRegfile(regfilemux::lw);
							lbu:loadRegfile(regfilemux::lbu);
							lhu:loadRegfile(regfilemux::lhu);
							default: loadRegfile(regfilemux::lw);
						endcase
					end
		op_store: begin
						loadMAR(marmux::alu_out);
						setALU(alumux::rs1_out, alumux::s_imm, 1'b1);
						if(~flush) cw.mem_write = 1'b1;
						setRS1valid();
						setRS2valid();
						unique case (store_funct3_t'(cw.funct3))
							sw: cw.wmask = 4'b1111;
							sh: cw.wmask = 4'b0011;
							sb: cw.wmask = 4'b0001;
							default: cw.wmask = 4'b0;
						endcase
					 end
		op_imm: begin 
						setRS1valid();
						setRDvalid();
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
						setRS1valid();
						setRS2valid();
						setRDvalid();
						unique case(cw.funct7)
						//multiply funct7: 0000001
							7'b0000001: begin
												;
											end 
							default:
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
					endcase
			end 
		default: ;
	 endcase
end 

endmodule: control