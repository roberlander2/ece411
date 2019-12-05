import rv32i_types::*;

module mp3_tb;

timeunit 100ps;
timeprecision 100ps;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
int timeout = 1000000;   // Feel Free to adjust the timeout value
int mispredicts_BP;
int mispredicts_SNT;
int num_inst;
int l2_resp_count;
int pmem_mem_access_count;
int cache_stall_cycles;

initial begin
    itf.halt = 1'b0;
    mispredicts_BP = 1'b0;
    mispredicts_SNT = 1'b0;
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
    if (dut.arbiter.pmem_resp) begin
        l2_resp_count <= l2_resp_count + 1;
    end
    if (dut.level_two.pmem_resp) begin
        pmem_mem_access_count <= pmem_mem_access_count + 1;
    end
    if (~dut.load_pipeline) begin
        cache_stall_cycles <= cache_stall_cycles + 1;
    end
    if(dut.dp.mispredict && dut.dp.load_pipeline) begin
      mispredicts_BP <= mispredicts_BP + 1;
    end
    if(dut.dp.br_en && dut.dp.load_pipeline) begin
      mispredicts_SNT <= mispredicts_SNT + 1;
    end
    if(dut.dp.load_pipeline) begin
      num_inst <= num_inst + 1;
    end

    if (itf.halt) begin
        $display("Tournament Branch Predictor Mispredicts: %0d", mispredicts_BP);
        $display("Static-Not-Taken Branch Predictor Mispredicts: %0d", mispredicts_SNT);
        $display("L2 mem_resp count = %0d", l2_resp_count);
        $display("pmem_access count = %0d", pmem_mem_access_count);
        $display("cache stall cycles = %0d", cache_stall_cycles);
        $finish;
    end
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
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

physical_memory physical_memory(
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
