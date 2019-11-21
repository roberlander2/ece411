import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
int timeout = 1000000;   // Feel Free to adjust the timeout value
int correct;
int num_inst;

initial begin
    itf.halt = 1'b0;
    correct = 1'b0;
    num_inst = 1'b0;
end
/************************* Error Halting Conditions **************************/
// Stop simulation on memory error detection
always @(posedge itf.clk iff itf.pm_error) begin
    $display("TOP: Halting on Physical Memory Error at time = %0t ps", $time);
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (dut.dp.load_pc && (dut.dp.memwb_pc_out == dut.dp.ifid_pc_out) && dut.dp.idex_cw.flush && dut.dp.exmem_cw.flush) begin
        itf.halt <= 1'b1;
    end
    if (itf.halt) begin
      $display("Correct: %d, Total Instructions: %d", correct, num_inst);
      $finish;
    end
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    if(dut.dp.resolution && dut.dp.load_pipeline) begin
      correct <= correct + 1;
    end

    if(dut.dp.load_pipeline) begin
      num_inst <= num_inst + 1;
    end

    timeout <= timeout - 1;
end

// Simulataneous Memory Read and Write
always @(posedge itf.clk iff (itf.pmem_read && itf.pmem_write))
    $error("@%0t TOP: Simultaneous memory read and write detected", $time);

/*****************************************************************************/
// Change inputs and outputs to match

mp3 dut(
    .clk          (itf.clk),
    .pmem_resp    (itf.pmem_resp),
    .pmem_rdata   (itf.pmem_rdata),
    .pmem_write   (itf.pmem_write),
    .pmem_address (itf.pmem_address),
    .pmem_wdata   (itf.pmem_wdata),
    .pmem_read    (itf.pmem_read)
);

memory physical_memory(
    .clk      (itf.clk),
    .read     (itf.pmem_read),
    .write    (itf.pmem_write),
    .address  (itf.pmem_address),
    .wdata    (itf.pmem_wdata),
    .resp     (itf.pmem_resp),
    .error    (itf.pm_error),
    .rdata    (itf.pmem_rdata)
);

endmodule : mp3_tb
