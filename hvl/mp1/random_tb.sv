import rv32i_types::*;

/**
 * Generates constrained random vectors with which to drive the DUT.
 * Recommended usage is to test arithmetic and comparator functionality,
 * as well as branches.
 *
 * Randomly testing load/stores will require building a memory model,
 * which you can do using a SystemVerilog associative array:
 *     logic[7:0] byte_addressable_mem [logic[31:0]]
 *   is an associative array with value type logic[7:0] and
 *   key type logic[31:0].
 * See IEEE 1800-2017 Clause 7.8
**/
module random_tb(
    tb_itf.tb itf,
    tb_itf.mem mem_itf,
    input logic [31:0] registers [32]
);

/**
 * SystemVerilog classes can be defined inside modules, in which case
 *   their usage scope is constrained to that module
 * RandomInst generates constrained random test vectors for your
 * rv32i DUT.
 * As is, RandomInst only supports generation of op_imm opcode instructions.
 * You are highly encouraged to expand its functionality.
**/
class RandomInst;
    rv32i_reg reg_range[$];
    arith_funct3_t arith3_range[$];

    /** Constructor **/
    function new();
        arith_funct3_t af3;
        af3 = af3.first;

        for (int i = 0; i < 32; ++i)
            reg_range.push_back(i);
        do begin
            arith3_range.push_back(af3);
            af3 = af3.next;
        end while (af3 != af3.last);

    endfunction

    function rv32i_word immediate(
        const ref rv32i_reg rd_range[$] = reg_range,
        const ref arith_funct3_t funct3_range[$] = arith3_range,
        const ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [11:0] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_imm;

        // Set rd register
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        // set funct3
        do begin
            word.i_word.funct3 = $urandom();
        end while (!(word.i_word.funct3 inside {funct3_range}));

        if(word.i_word.funct3 == 3'b101) begin
          word.i_word.i_imm[11:5] = word.i_word.i_imm[5] ? 7'b0000000 : 7'b0100000;
        end

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        // set immediate value
        word.i_word.i_imm = $urandom();

        return word.rvword;
    endfunction

    function rv32i_word register(
        const ref rv32i_reg rd_range[$] = reg_range,
        const ref arith_funct3_t funct3_range[$] = arith3_range,
        const ref rv32i_reg rs1_range[$] = reg_range,
        const ref rv32i_reg rs2_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [6:0] funct7;
                rv32i_reg rs1;
                rv32i_reg rs2;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_reg;

        word.i_word.funct7 = $urandom();
        word.i_word.funct7 = word.i_word.funct7[0] ? 7'b0000000 : 7'b0100000;

        // Set rd register
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        // set funct3
        do begin
            word.i_word.funct3 = $urandom();
        end while (!(word.i_word.funct3 inside {funct3_range}));

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        // set rs1
        do begin
            word.i_word.rs2 = $urandom();
        end while (!(word.i_word.rs2 inside {rs2_range}));

        return word.rvword;
    endfunction

    function rv32i_word lui(
        const ref rv32i_reg rd_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [19:0] u_imm;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } u_word;
        } word;

        word.rvword = '0;
        word.u_word.opcode = op_lui;

        // Set rd register
        do begin
            word.u_word.rd = $urandom();
        end while (!(word.u_word.rd inside {rd_range}));

          word.u_word.u_imm = $urandom();
        return word.rvword;
    endfunction

    function rv32i_word auipc(
        const ref rv32i_reg rd_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [19:0] u_imm;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } u_word;
        } word;

        word.rvword = '0;
        word.u_word.opcode = op_auipc;

        // Set rd register
        do begin
            word.u_word.rd = $urandom();
        end while (!(word.u_word.rd inside {rd_range}));

          word.u_word.u_imm = $urandom();
        return word.rvword;
    endfunction

    function rv32i_word load(
        input logic [2:0] funct3,
        const ref rv32i_reg rd_range[$] = reg_range,
        const ref arith_funct3_t funct3_range[$] = arith3_range,
        const ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [11:0] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_load;

        // Set rd register4
        do begin
            word.i_word.rd = $urandom();
        end while (!(word.i_word.rd inside {rd_range}));

        // set funct3
        word.i_word.funct3 = funct3;

        // set rs1
        do begin
            word.i_word.rs1 = $urandom();
        end while (!(word.i_word.rs1 inside {rs1_range}));

        word.i_word.i_imm = $urandom();
        if(funct3 == 3'b010) begin
          unique case(registers[word.i_word.rs1][1:0])
            2'b00:   word.i_word.i_imm[1:0] = 2'b00;
            2'b01:   word.i_word.i_imm[1:0] = 2'b11;
            2'b10:   word.i_word.i_imm[1:0] = 2'b10;
            2'b11:   word.i_word.i_imm[1:0] = 2'b01;
          endcase
        end
        return word.rvword;
    endfunction

    function rv32i_word store(
        input logic [2:0] funct3,
        const ref rv32i_reg rd_range[$] = reg_range,
        const ref arith_funct3_t funct3_range[$] = arith3_range,
        const ref rv32i_reg rs1_range[$] = reg_range,
        const ref rv32i_reg rs2_range[$] = reg_range

    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [6:0] s_imm;
                rv32i_reg rs2;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] imm;
                rv32i_opcode opcode;
            } s_word;
        } word;

        word.rvword = '0;
        word.s_word.opcode = op_store;

        // Set rd register
        word.s_word.imm = $urandom();

        // set funct3
        word.s_word.funct3 = funct3;

        // set rs1
        do begin
            word.s_word.rs1 = $urandom();
        end while (!(word.s_word.rs1 inside {rs1_range}));

        // set rs2
        do begin
            word.s_word.rs2 = $urandom();
        end while (!(word.s_word.rs2 inside {rs2_range}));


        word.s_word.s_imm = $urandom();
        if(funct3 == 3'b010) begin
            unique case(registers[word.s_word.rs1][1:0])
              2'b00:   word.s_word.imm[1:0] = 2'b00;
              2'b01:   word.s_word.imm[1:0] = 2'b11;
              2'b10:   word.s_word.imm[1:0] = 2'b10;
              2'b11:   word.s_word.imm[1:0] = 2'b01;
            endcase
        end
        else if(funct3 == 3'b001) begin
          word.s_word.imm[0] = registers[word.s_word.rs1][0];
        end

        return word.rvword;
    endfunction

    function rv32i_word jal(
        const ref rv32i_reg rd_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic imm1;
                logic [9:0] imm2;
                logic imm3;
                logic [7:0] imm4;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } j_word;
        } word;

        word.rvword = '0;
        word.j_word.opcode = op_jal;

        // Set rd register
        do begin
            word.j_word.rd = $urandom();
        end while (!(word.j_word.rd inside {rd_range}));


          word.j_word.imm1 = $urandom();
          word.j_word.imm2 = $urandom();
          word.j_word.imm2[0] = 1'b0;
          word.j_word.imm3 = $urandom();
          word.j_word.imm4 = $urandom();
        return word.rvword;
    endfunction

    function rv32i_word jalr(
      const ref rv32i_reg rd_range[$] = reg_range,
      const ref arith_funct3_t funct3_range[$] = arith3_range,
      const ref rv32i_reg rs1_range[$] = reg_range
    );
        union {
            rv32i_word rvword;
            struct packed {
                logic [11:0] i_imm;
                rv32i_reg rs1;
                logic [2:0] funct3;
                logic [4:0] rd;
                rv32i_opcode opcode;
            } i_word;
        } word;

        word.rvword = '0;
        word.i_word.opcode = op_jalr;

        word.i_word.funct3 = 3'b0;

        // Set rd register
        do begin
            word.i_word.rd = $urandom;
        end while (!(word.i_word.rd inside {rd_range}));


        //set rs1
        do begin
            word.i_word.rd = $urandom;
        end while (!(word.i_word.rs1 inside {rs1_range}));


          word.i_word.i_imm = $urandom();
          unique case(registers[word.i_word.rs1][1:0])
            2'b00:   word.i_word.i_imm[1:0] = 2'b00;
            2'b01:   word.i_word.i_imm[1:0] = 2'b11;
            2'b10:   word.i_word.i_imm[1:0] = 2'b10;
            2'b11:   word.i_word.i_imm[1:0] = 2'b01;
          endcase
        return word.rvword;
    endfunction

endclass

RandomInst generator = new();

task immediate_tests(input int count, input logic verbose = 1'b0);
    $display("Starting Immediate Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.immediate();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing Immediate Tests");
endtask


task registers_tests(input int count, input logic verbose = 1'b0);
    $display("Starting Register Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.register();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing Register Tests");
endtask

task lui_tests(input int count, input logic verbose = 1'b0);
    $display("Starting LUI Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.lui();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing LUI Tests");
endtask

task auipc_tests(input int count, input logic verbose = 1'b0);
    $display("Starting AUIPC Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.auipc();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing AUIPC Tests");
endtask

task load_tests(input int count, input logic [2:0] funct3, input logic verbose = 1'b0);
    $display("Starting LOAD Tests for %3b", funct3);
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.load(funct3);
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing LOAD Tests for %3b", funct3);
endtask

task store_tests(input int count, input logic [2:0] funct3, input logic verbose = 1'b0);
    $display("Starting STORE Tests for %3b", funct3);
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.store(funct3);
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
    end
    $display("Finishing STORE Tests for %3b", funct3);
endtask

task jal_tests(input int count, input logic verbose = 1'b0);
    $display("Starting JAL Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.jal();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing JAL Tests");
endtask

task jalr_tests(input int count, input logic verbose = 1'b0);
    $display("Starting JALR Tests");
    repeat (count) begin
        @(negedge itf.clk iff itf.mem_read);
        mem_itf.mem_rdata = generator.jalr();
        if (verbose)
            $display("Testing stimulus: %32h", mem_itf.mem_rdata);
        mem_itf.mem_resp = 1;
        @(negedge itf.clk);
        mem_itf.mem_resp = 0;
    end
    $display("Finishing JALR Tests");
endtask

initial begin
    mem_itf.mem_rdata = 32'h013;
    immediate_tests(200000, 1'b0);
    registers_tests(200000, 1'b0);
    lui_tests(200000, 1'b0);
    auipc_tests(200000, 1'b0);
    load_tests(200000, 3'b000, 1'b0);
    load_tests(200000, 3'b001, 1'b0);
    load_tests(200000, 3'b010, 1'b0);
    load_tests(200000, 3'b100, 1'b0);
    load_tests(200000, 3'b101, 1'b0);
    store_tests(200000, 3'b000, 1'b0);
    store_tests(200000, 3'b001, 1'b0);
    store_tests(200000, 3'b010, 1'b0);
    jal_tests(200000, 1'b0);
    jalr_tests(200000, 1'b0);
    $finish;
end

endmodule : random_tb
