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
localparam ghr_size = 10;
//loads
logic load_pc;
logic is_br;
logic is_jalr;
logic is_jal;
logic is_jalr_mem;
logic is_jal_mem;

logic load_ghr;
logic read_gst;
logic update_gst;
logic [ghr_size-1:0] ghr_out;
logic resolution;

//mux outputs
rv32i_word pcmux1_out;
rv32i_word pcmux2_out;
rv32i_word pc_in;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmpmux_out;
rv32i_word regfilemux_out;
rv32i_word mem_addressmux_out;

//mux selects
bpredmux::bpredmux1_sel_t bpmux1_sel;
bpredmux::bpredmux2_sel_t bpmux2_sel;

//module outputs
control_word_t cw;
control_word_t cw_mux_out;
rv32i_word alu_out;
logic [63:0] mul_out;
logic [31:0] mul_res;
logic [31:0] exmem_mul_res;
logic [31:0] mul1_in;
logic [31:0] mul2_in;
logic mul_rdy;
logic exmem_mul_rdy;
logic mul_done;
logic [31:0] quotient;
logic [31:0] remainder;
logic [31:0] exmem_remainder;
logic [31:0] exmem_quotient;
logic [31:0] dividend;
logic [31:0] divisor;
logic div_rdy;
logic div_done;
logic exmem_div_rdy;
logic cmp_out;
logic mispredict; //flush due to a mispredict
logic mispred_flush;
logic br_en;
logic flush;
logic branch_taken;
logic pred_sel;
logic prediction;
logic local_prediction;
logic global_prediction;
logic gshare_prediction;
logic btb_hit;
logic localtable_prediction;
logic globaltable_prediction;
logic gsharetable_prediction;
rv32i_word target;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word pc_out;

//pipeline signals
rv32i_word ifid_pc_out;
logic ifid_pred;
logic ifid_pred_sel;
logic [9:0] ifid_ghr_out;

rv32i_word idex_pc_out;
logic idex_pred;
logic idex_pred_sel;
logic [9:0] idex_ghr_out;
rv32i_word idex_rs1_out;
rv32i_word idex_rs2_out;
control_word_t idex_cw;

rv32i_word exmem_pc_out;
rv32i_word exmem_alu_out;
rv32i_word comp_mux_out;
rv32i_word exmem_rs2_out;
rv32i_word exmem_cmp_out;
control_word_t exmem_cw;
logic exmem_reso;

rv32i_word memwb_pc_out;
rv32i_word memwb_comp_out;
rv32i_word memwb_cmp_out;
rv32i_word memwb_rs2_out;
control_word_t memwb_cw;
rv32i_word alu_in1;
rv32i_word alu_in2;
rv32i_word alu_in11;
rv32i_word alu_in22;
rv32i_word cmp_in1;
rv32i_word cmp_in2;
rv32i_word exmem_rs2_in;
rv32i_word memex_forward;
rv32i_word rs1_in;
rv32i_word rs2_in;
rv32i_word mem_wdata_forward;

rv32i_word memwb_mem_address;
logic [1:0] mem_addrmod4;
logic [4:0] mem_addrmod4_mult;
rv32i_word mdrreg_bytemask;
rv32i_word mdrreg_halfmask;

logic is_mult;
logic is_div;

assign mul_res = (mul_done) ? ((idex_cw.half_sel) ? mul_out[63:32] : mul_out[31:0]) : 32'bX;

assign mem_addrmod4 = memwb_mem_address[1:0];
assign mem_addrmod4_mult = mem_addrmod4 << 3;
assign mdrreg_bytemask = (mem_rdata & (32'h000000FF << mem_addrmod4_mult)) >> mem_addrmod4_mult;
assign mdrreg_halfmask = (mem_rdata & (32'h0000FFFF << mem_addrmod4_mult)) >> mem_addrmod4_mult;

assign inst_addr = pc_out;
assign mem_address = mem_addressmux_out;
assign iread = 1'b1;
assign load_pc = load_pipeline;
assign br_en = ((idex_cw.opcode == op_br) && cmp_out) && ~idex_cw.flush; //execute stage 
//assign br_en_flush = ((exmem_cw.opcode == op_br) && exmem_cmp_out) && ~exmem_cw.flush; //memory stage 
assign flush = mispredict || mispred_flush || is_jalr || is_jal || is_jalr_mem || is_jal_mem; //need to change now
assign is_jalr = (idex_cw.opcode == op_jalr) && ~idex_cw.flush;
assign is_jal = (idex_cw.opcode == op_jal) && ~idex_cw.flush;
assign is_br = (idex_cw.opcode == op_br) && ~idex_cw.flush;
assign load_ghr = is_br;
assign is_jalr_mem = (exmem_cw.opcode == op_jalr) && ~exmem_cw.flush;
assign is_jal_mem = (exmem_cw.opcode == op_jal) && ~exmem_cw.flush;
//use normal pc sel if neither of the two instructions in front is a branch
//assign pcmux_sel = pcmux::pcmux_sel_t'({is_jalr, (br_en || is_jal)});
//assign gshare_idx = ghr_out ^ pc_out[ghr_size-1 + 2:2];
assign resolution = (idex_pred == br_en) && (pcmux2_out == ifid_pc_out) || (~br_en == ~idex_pred);
assign local_prediction = localtable_prediction  && btb_hit && ~br_en;
assign gshare_prediction = gsharetable_prediction && btb_hit && ~br_en;
assign mispredict= ~resolution && ~idex_cw.flush; //if we have an incorrect prediction, need to flush
assign mispred_flush = ~exmem_reso && ~exmem_cw.flush;

assign bpmux1_sel = bpredmux::bpredmux1_sel_t'({mispredict, idex_pred});
assign bpmux2_sel = bpredmux::bpredmux2_sel_t'({is_jalr, is_jal});

assign mem_byte_enable = exmem_cw.wmask << mem_address[1:0];
assign dread = exmem_cw.mem_read;
assign dwrite = exmem_cw.mem_write;

assign is_mult = (idex_cw.opcode == op_reg && idex_cw.funct7 == 7'b0000001 && ~idex_cw.funct3[2]);
assign is_div = (idex_cw.opcode == op_reg && idex_cw.funct7 == 7'b0000001 && idex_cw.funct3[2]);

logic forward_exmem_rs1;
logic forward_memwb_rs1;
logic forward_exmem_rs2;
logic forward_memwb_rs2;
logic forward_memwb_id_rs1;
logic forward_memwb_id_rs2;
logic forward_wb2mem;
logic stall_rs1;
logic stall_rs2;
logic _stall;

assign alu_in11 = (exmem_cw.opcode == op_reg && exmem_cw.funct7 == 7'b0000001 && forward_exmem_rs1) ? (exmem_cw.funct3[2] ? (exmem_cw.funct3[1] ? exmem_remainder : exmem_quotient) : exmem_mul_res) : alu_in1;
assign alu_in22 = (exmem_cw.opcode == op_reg && exmem_cw.funct7 == 7'b0000001 && forward_exmem_rs2) ? (exmem_cw.funct3[2] ? (exmem_cw.funct3[1] ? exmem_remainder : exmem_quotient) : exmem_mul_res) : alu_in2;

assign _stall = (stall_rs1 || stall_rs2 ) && (idex_cw.opcode == op_load);
assign stall = _stall || (~exmem_mul_rdy || ~mul_rdy) || (~exmem_div_rdy || ~mul_rdy);
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

//Branch Predictor Datapath
gh_register  #(10) ghr(
	.clk(clk),
	.load(load_ghr),
	.in(br_en),
	.out(ghr_out)
);
/*
* TODO: create pipeline registers  for
* ghr_out, prediction, current;y just a local history pred table
*/
predict_table local_hist_table(
	 .clk(clk),
    .read(load_pipeline),
    .load(load_pipeline), //update predictor table  only in EXECUTE stage
    .rindex(pc_out[9:0]),
    .windex(idex_pc_out[9:0]),
	 .wtaken(idex_pred),
    .resolution(resolution),
    .prediction(localtable_prediction)
);


selector selector(
	.clk(clk),
	.load(load_pipeline && is_br),
	.read(load_pipeline),
	.pred_used(idex_pred_sel),
	.resolution(resolution),
	.pred_sel(pred_sel)
);

predict_table gshare_table(
	 .clk(clk),
    .read(load_pipeline),
    .load(load_pipeline), //update predictor table  only in EXECUTE stage
    .rindex(ghr_out ^ pc_out[9:0]),
    .windex(idex_ghr_out ^ idex_pc_out[9:0]),
	 .wtaken(idex_pred),
    .resolution(resolution),
    .prediction(gsharetable_prediction)
);

BTB btb(
	.clk(clk), 
	.rPC(pc_out),
	.wPC(idex_pc_out),
	.load(is_br && load_pipeline),
	.read(load_pipeline && ~stall),
	.wtarget(alu_out),
	.rtarget(target),
	.btb_hit(btb_hit)
);

//CPU datapath
//fetch
pc PC(
	.clk(clk),
	.load(load_pc && ~stall && mul_rdy),
	.in(pc_in),
	.out(pc_out)
);

//decode
regfile REGFILE(
	.clk(clk),
	.load(memwb_cw.load_regfile && (~memwb_cw.mem_read || load_pipeline)),
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
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

multiplier MUL(
	 .clk_i(clk),
	 .signed1(idex_cw.signed1),
	 .signed2(idex_cw.signed2),
    .multiplicand_i(mul1_in),
    .multiplier_i(mul2_in),
    .start_i(is_mult && load_pipeline),
    .ready_o(mul_rdy),
    .product_o(mul_out),
    .done_o(mul_done)
);

divider DIV(
	 .clk(clk),
	 .start_i(is_div && load_pipeline),
	 .dividend(dividend),
    .divisor(divisor),
	 .inputs_signed(idex_cw.signed1 || idex_cw.signed2),
	 .quotient(quotient),
    .remainder(remainder),
	 .ready(div_rdy),
	 .done(div_done)
);

cmp CMP (
	.a(cmp_in1),
	.b(cmpmux_out),
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

register #(1) ifid_prediction(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(prediction),
	 .out(ifid_pred)
);

register #(1) ifid_pred_used(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(pred_sel),
	 .out(ifid_pred_sel)
);

register #(10) ifid_ghr(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(ghr_out),
	 .out(ifid_ghr_out)
);

//ID/EX
register idex_PC(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (ifid_pc_out),
    .out  (idex_pc_out)
);

register #(1) idex_prediction(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(ifid_pred),
	 .out(idex_pred)
);

register #(1) idex_pred_used(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(ifid_pred_sel),
	 .out(idex_pred_sel)
);

register #(10) idex_ghr(
	 .clk(clk),
	 .load(load_pipeline && ~stall),
	 .in(ifid_ghr_out),
	 .out(idex_ghr_out)
);

register idex_RS1(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (rs1_in),
    .out  (idex_rs1_out)
);

register idex_RS2(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (rs2_in),
    .out  (idex_rs2_out)
);

cw_register idex_CW(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (cw_mux_out),
    .out  (idex_cw)
);

//EX/MEM
register #(1) exmem_resolution(
	 .clk(clk),
	 .load(load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
	 .in(resolution),
	 .out(exmem_reso)
);

register exmem_PC(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (idex_pc_out),
    .out  (exmem_pc_out)
);

register exmem_ALU(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (alu_out),
    .out  (exmem_alu_out)
);

register exmem_MUL(
    .clk  (clk),
    .load (load_pipeline && mul_done),
    .in   (mul_res),
    .out  (exmem_mul_res)
);

register #(1) exmem_MUL_RDY(
    .clk  (clk),
    .load (load_pipeline),
    .in   (mul_rdy),
    .out  (exmem_mul_rdy)
);

register exmem_DIVQ(
    .clk  (clk),
    .load (load_pipeline && div_done),
    .in   (quotient),
    .out  (exmem_quotient)
);
register exmem_DIVR(
    .clk  (clk),
    .load (load_pipeline && div_done),
    .in   (remainder),
    .out  (exmem_remainder)
);

register #(1) exmem_DIV_RDY(
    .clk  (clk),
    .load (load_pipeline),
    .in   (div_rdy),
    .out  (exmem_div_rdy)
);


register exmem_RS2(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (exmem_rs2_in),
    .out  (exmem_rs2_out)
);

register exmem_CMP(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   ({31'b0, cmp_out}), //perform ZEXT here?
    .out  (exmem_cmp_out)
);

cw_register exmem_CW(
    .clk  (clk),
    .load (load_pipeline && exmem_mul_rdy && exmem_div_rdy && mul_rdy && div_rdy),
    .in   (idex_cw),
    .out  (exmem_cw)
);

//MEM/WB
register memwb_PC(
    .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (exmem_pc_out),
    .out  (memwb_pc_out)
);

register memwb_COMP(
    .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (comp_mux_out),
    .out  (memwb_comp_out)
);

register memwb_RS2(
    .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (exmem_rs2_out),
    .out  (memwb_rs2_out)
);

register memwb_CMP(
    .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (exmem_cmp_out), //perform ZEXT here?
    .out  (memwb_cmp_out)
);

register memwb_mem_addr(
	 .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (mem_address), //perform ZEXT here?
    .out  (memwb_mem_address)
);

cw_register memwb_CW(
    .clk  (clk),
    .load (load_pipeline && mul_rdy && div_rdy),
    .in   (exmem_cw),
    .out  (memwb_cw)
);

//forwarding logic
always_comb begin
	unique case (forward_wb2mem)
		1'b0: mem_wdata_forward = exmem_rs2_out;
		1'b1: mem_wdata_forward = regfilemux_out;
		default: mem_wdata_forward = exmem_rs2_out;
	endcase
	unique case({forward_exmem_rs1, forward_memwb_rs1})
		2'b00: begin
					alu_in1 = idex_rs1_out;
					cmp_in1 = idex_rs1_out;
					mul1_in = idex_rs1_out;
					dividend = idex_rs1_out;
				 end
		2'b01: begin
					alu_in1 = regfilemux_out;
					cmp_in1 = regfilemux_out;
					mul1_in = regfilemux_out;
					dividend = regfilemux_out;
				 end
		2'b10: begin
					alu_in1 = memex_forward;
					cmp_in1 = memex_forward;
					mul1_in = memex_forward;
					dividend = memex_forward;
				 end
		2'b11: begin
					alu_in1 = memex_forward;
					cmp_in1 = memex_forward;
					mul1_in = memex_forward;
					dividend = memex_forward;
				 end
		default: begin
						alu_in1 = idex_rs1_out;
						cmp_in1 = idex_rs1_out;
						mul1_in = idex_rs1_out;
						dividend = idex_rs1_out;
					end
	endcase
	
	unique case({forward_exmem_rs2, forward_memwb_rs2})
		2'b00: begin
					alu_in2 = idex_rs2_out;
					cmp_in2 = idex_rs2_out;
					exmem_rs2_in = idex_rs2_out;
					mul2_in = idex_rs2_out;
					divisor = idex_rs2_out;
				 end
		2'b01: begin
					alu_in2 = regfilemux_out;
					cmp_in2 = regfilemux_out;
					exmem_rs2_in = regfilemux_out;
					mul2_in = regfilemux_out;
					divisor = regfilemux_out;
				 end
		2'b10: begin
					alu_in2 = memex_forward;
					cmp_in2 = memex_forward;
					exmem_rs2_in = memex_forward;
					mul2_in = memex_forward;
					divisor = memex_forward;
				 end
		2'b11: begin
					alu_in2 = memex_forward;
					cmp_in2 = memex_forward;
					exmem_rs2_in = memex_forward;
					mul2_in = memex_forward;
					divisor = memex_forward;
				 end
		default: begin
						alu_in2 = memex_forward;
						cmp_in2 = idex_rs2_out;
						exmem_rs2_in = idex_rs2_out;
						mul2_in = idex_rs2_out;
						divisor = idex_rs2_out;
					end
	endcase
	
	unique case (exmem_cw.regfilemux_sel)
//		regfilemux::alu_out: begin
//										if(exmem_cw.opcode == op_reg && exmem_cw.funct7 == 7'b0000001)
//											memex_forward = exmem_cw.funct3[2] ? (exmem_cw.funct3[1] ? exmem_remainder : exmem_quotient) : exmem_mul_res;
//										else
//											memex_forward = exmem_alu_out;
//									end
		regfilemux::alu_out: memex_forward = exmem_alu_out;
		regfilemux::br_en: memex_forward = exmem_cmp_out;
		regfilemux::u_imm: memex_forward = exmem_cw.u_imm;
		regfilemux::pc_plus4: memex_forward = exmem_pc_out + 4;
		default: memex_forward = 32'hXXXXXXXX;
	endcase
	 
	unique case (forward_memwb_id_rs1)
		1'b1: rs1_in = regfilemux_out;
		1'b0: rs1_in = rs1_out;
		default: rs1_in = rs1_out;
	endcase
	 
	unique case (forward_memwb_id_rs2)
		1'b1: rs2_in = regfilemux_out;
		1'b0: rs2_in = rs2_out;
		default: rs2_in = rs2_out;
	endcase
	 
	unique case (stall)
		1'b0: cw_mux_out = cw;
		1'b1: cw_mux_out = 0;
		default: cw_mux_out = cw;
	endcase
end


always_comb begin	 
//	 //fetch
//    unique case (pcmux_sel & mispredict)	
//        pcmux::pc_plus4: pcmux_out = idex_pc_out + 4;
//		  pcmux::alu_out: pcmux_out = alu_out;
//		  pcmux::alu_mod2: pcmux_out = alu_out & 32'hFFFFFFFE;
//        default: pcmux_out = pc_out + 4;
//    endcase

	 unique case(bpmux1_sel)
		bpredmux::not_taken_correct: pcmux1_out = pc_out + 4;
		bpredmux::taken_correct: pcmux1_out = pc_out + 4;
		bpredmux::alu_out: pcmux1_out = alu_out;
		bpredmux::taken_incorrect: pcmux1_out = idex_pc_out + 4;
	 endcase
	 
	  unique case(bpmux2_sel)
		bpredmux::bpmux1 : pcmux2_out = pcmux1_out;
		bpredmux::jal: pcmux2_out = alu_out;
		bpredmux::jalr: pcmux2_out = alu_out & 32'hFFFFFFFE;
		default: pcmux2_out = pcmux1_out;
	  endcase
	 
	 unique case(pred_sel)
		1'b0: prediction = local_prediction;
		1'b1: prediction = gshare_prediction;
		default: prediction = local_prediction;
	 endcase
	 
	 unique case(prediction)
		1'b0:pc_in = pcmux2_out;
		1'b1:pc_in = target;
		default: pc_in = pcmux2_out;
	 endcase
	 
	 
	 //execute
	 unique case (idex_cw.alumux1_sel)
		 alumux::rs1_out: alumux1_out = alu_in11;
		 alumux::pc_out: alumux1_out = idex_pc_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (idex_cw.alumux2_sel)
		 alumux::i_imm: alumux2_out = idex_cw.i_imm;
		 alumux::u_imm: alumux2_out = idex_cw.u_imm;
		 alumux::b_imm: alumux2_out = idex_cw.b_imm;
		 alumux::s_imm: alumux2_out = idex_cw.s_imm;
		 alumux::j_imm: alumux2_out = idex_cw.j_imm;
		 alumux::rs2_out: alumux2_out = alu_in22;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case (idex_cw.cmpmux_sel)
		 cmpmux::rs2_out: cmpmux_out = cmp_in2;
		 cmpmux::i_imm: cmpmux_out = idex_cw.i_imm;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 //memory
	 unique case (exmem_cw.marmux_sel)
		 marmux::pc_out: mem_addressmux_out = exmem_pc_out;
		 marmux::alu_out: mem_addressmux_out = exmem_alu_out;
		 default: `BAD_MUX_SEL;
	 endcase
	 
	 unique case(exmem_cw.opcode == op_reg && exmem_cw.funct7 == 7'b0000001)
		1'b0: comp_mux_out = exmem_alu_out;
		1'b1: comp_mux_out = exmem_cw.funct3[2] ? (exmem_cw.funct3[1] ? remainder : quotient) : mul_res;
	 endcase
	 
	 //write back
	 unique case (memwb_cw.regfilemux_sel)
		 regfilemux::alu_out: regfilemux_out = memwb_comp_out;
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