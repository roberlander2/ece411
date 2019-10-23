import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
int timeout = 100000000;   // Feel Free to adjust the timeout value
int halt_count = 0;

initial begin
    itf.halt = 1'b0;
end
/************************* Error Halting Conditions **************************/
// Stop simulation on memory error detection
// always @(posedge itf.clk iff itf.pm_error) begin
//     $display("TOP: Halting on Physical Memory Error at time = %0t ps", $time);
// end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (dut.dp.load_pc && dut.dp.pc_out == 8'h00000144) begin
        halt_count <= halt_count + 1;
        if (halt_count == 3)
            itf.halt <= 1'b1;
    end
    if (itf.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

// Simulataneous Memory Read and Write
// always @(posedge itf.clk iff (itf.mem_read && itf.mem_write))
//     $error("@%0t TOP: Simultaneous memory read and write detected", $time);

/*****************************************************************************/
// Change inputs and outputs to match
mp3 dut(
    .clk        (itf.clk),
    .read_a     (itf.read_a),
    .address_a  (itf.address_a),
    .resp_a     (itf.resp_a),
    .rdata_a    (itf.rdata_a),
    .read_b     (itf.read_b),
    .write      (itf.write),
    .wmask      (itf.wmask),
    .address_b  (itf.address_b),
    .wdata      (itf.wdata),
    .resp_b     (itf.resp_b),
    .rdata_b    (itf.rdata_b)
);

// Change inputs and outputs to match
magic_memory_dp magic_memory(
    .clk        (itf.clk),
    .read_a     (itf.read_a),
    .address_a  (itf.address_a),
    .resp_a     (itf.resp_a),
    .rdata_a    (itf.rdata_a),
    .read_b     (itf.read_b),
    .write      (itf.write),
    .wmask      (itf.wmask),
    .address_b  (itf.address_b),
    .wdata      (itf.wdata),
    .resp_b     (itf.resp_b),
    .rdata_b    (itf.rdata_b)
);

endmodule : mp3_tb
