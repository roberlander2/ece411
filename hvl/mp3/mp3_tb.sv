import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
int timeout = 100000000;   // Feel Free to adjust the timeout value

/************************* Error Halting Conditions **************************/
// Stop simulation on memory error detection
// always @(posedge itf.clk iff itf.pm_error) begin
//     $display("TOP: Halting on Physical Memory Error at time = %0t ps", $time);
// end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
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
    .clk              (itf.clk),
    .mem_address      (mem_address_in),
   	.mem_wdata        (mem_wdata_in),
 	  .mem_byte_enable  (mem_byte_enable_in),
   	.mem_read         (mem_read_in),
 	  .mem_write        (mem_write_in),
    .pmem_resp        (itf.mem_resp),
    .pmem_rdata       (itf.mem_rdata),

    .mem_rdata        (mem_rdata_out),
 	  .mem_resp         (mem_resp_out),
    .pmem_read        (itf.mem_read),
    .pmem_write       (itf.mem_write),
    .pmem_address     (itf.mem_address),
    .pmem_wdata       (itf.mem_wdata)
);

// Change inputs and outputs to match
magic_memory_dp magic_memory(
    .clk     (itf.clk),
    .read    (itf.mem_read),
    .write   (itf.mem_write),
    .address (itf.mem_address),
    .wdata   (itf.mem_wdata),
    .resp    (itf.mem_resp),
    .rdata   (itf.mem_rdata),
    .error   (itf.pm_error)
);

endmodule : mp3_tb
