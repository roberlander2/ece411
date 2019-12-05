/**
 * Interface used by testbenches to communicate with memory and
 * the DUT.
**/
interface tb_itf;

timeunit 100ps;
timeprecision 100ps;

bit clk;

logic pmem_resp;
logic [255:0] pmem_rdata;
logic pmem_write;
logic [31:0] pmem_address;
logic [255:0] pmem_wdata;
logic pmem_read;

// Other
logic [15:0] errcode;
logic halt;
logic sm_error;
logic pm_error;

// The monitor has a reset signal, which it needs, but
// you use initial blocks in your DUT, so we generate two clocks
initial begin
    clk = '0;
    #40;
end

always #47.5 clk = ~clk;

endinterface : tb_itf
