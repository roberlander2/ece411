import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
// tb_itf ditf();
int timeout = 100000000;   // Feel Free to adjust the timeout value
int good_count = 0;

initial begin
    itf.halt = 1'b0;
end
/************************* Error Halting Conditions **************************/
// Stop simulation on memory error detection
always @(posedge itf.clk iff itf.pm_error) begin
    $display("TOP: Halting on Physical Memory Error at time = %0t ps", $time);
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    // CP1 halt address = 168
    // CP2 halt address = 154
    if (dut.dp.load_pc && (dut.dp.pc_out == 32'h00000168)) begin
        good_count <= good_count + 1;
        if (good_count == 1)
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

// .dpmem_resp    (ditf.pmem_resp),
// .dpmem_rdata   (ditf.pmem_rdata),
// .dpmem_write   (ditf.pmem_write),
// .dpmem_address (ditf.pmem_address),
// .dpmem_wdata   (ditf.pmem_wdata),
// .dpmem_read    (ditf.pmem_read)

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

// memory dphysical_memory(
//     .clk      (ditf.clk),
//     .read     (ditf.pmem_read),
//     .write    (ditf.pmem_write),
//     .address  (ditf.pmem_address),
//     .wdata    (ditf.pmem_wdata),
//     .resp     (ditf.pmem_resp),
//     .error    (ditf.pm_error),
//     .rdata    (ditf.pmem_rdata)
// );

// FOR USE WITHOUT THE ARBITER (PUT INTO MP3.SV)
//dcache dcache(
//	.clk					(clk),
//	.mem_write			(dwrite),
//	.mem_read			(dread),
//	.pmem_resp			(dpmem_resp),
//	.pmem_rdata			(dpmem_rdata),
//	.mem_wdata			(mem_wdata),
//	.mem_address		(mem_address),
//	.mem_byte_enable	(mem_byte_enable),
//	.load_ipipeline	(iload_pipeline),
//	.pmem_read			(dpmem_read),
//	.pmem_write			(dpmem_write),
//	.pmem_wdata			(dpmem_wdata),
//	.pmem_address		(dpmem_address),
//	.mem_rdata			(mem_rdata),
//	.load_pipeline 	(dload_pipeline)
//);

// FOR USE WITHOUT THE ARBITER (PUT INTO MP3.SV)
//icache icache(
//	.clk				(clk),
//	.mem_read		(iread),
//	.pmem_resp		(pmem_resp),
//	.pmem_rdata		(pmem_rdata),
//	.mem_address	(inst_addr),
//	.load_dpipeline 	(dload_pipeline),
//	.pmem_read		(pmem_read),
//	.pmem_address	(pmem_address),
//	.mem_rdata		(inst),
//	.load_pipeline (iload_pipeline)
//);

// FOR USE WITHOUT THE ARBITER (PUT INTO MP3.SV)
//	input dpmem_resp,
//	input [255:0] dpmem_rdata,
//	output logic dpmem_write,
//	output rv32i_word dpmem_address,
//	output logic [255:0] dpmem_wdata,
//	output logic dpmem_read

endmodule : mp3_tb
