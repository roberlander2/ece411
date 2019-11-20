module pseudo_lru_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
bit clk;
int timeout = 1000000;
logic valid;
logic [2:0] way_out;
logic load_lru;

// Stop simulation on timeout (stall detection), halt
always @(posedge clk) begin
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

pseudo_lru #(8) dut(.*);

task pseudo_lru_tests(input int count);
    $display("Starting Pseudo LRU Tests");
    repeat (count) begin
        load_lru = 1'b1;
        @(posedge clk);
        load_lru = 1'b0;
        @(posedge clk iff valid);
        $display("LRU way = %3b at time = %0t", way_out, $time);
    end
    $display("Finishing Pseudo LRU Tests");
endtask

initial begin
    clk = '0;
    load_lru = 1'b0;
    #40;
    pseudo_lru_tests(1000);
    $finish;
end

always #5 clk = ~clk;

endmodule : pseudo_lru_tb
