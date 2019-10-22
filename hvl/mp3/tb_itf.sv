/**
 * Interface used by testbenches to communicate with memory and
 * the DUT.
**/
interface tb_itf;

timeunit 1ns;
timeprecision 1ns;

bit clk;

// Port A
logic read_a;
logic [31:0] address_a
logic resp_a;
logic [31:0] rdata_a;

// Port B
logic read_b;
logic write;
logic [3:0] wmask;
logic [31:0] address_b;
logic [31:0] wdata;
logic resp_b;
logic [31:0] rdata_b;

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

always #5 clk = ~clk;

endinterface : tb_itf
