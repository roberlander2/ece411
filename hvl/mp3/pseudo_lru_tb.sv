module pseudo_lru_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
bit clk;
int timeout = 1000000;
logic valid;
logic [2:0] way_out;
logic load_lru;
logic [7:0] way_onehot;
logic hit;
logic [2:0] hit_way;

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
        hit = $urandom();
        hit_way = $urandom();
        way_onehot = hit << hit_way;
        load_lru = 1'b1;
        @(posedge clk);
        load_lru = 1'b0;
        @(posedge clk iff valid);
        $display("Hit vector = %8b: LRU way = %3b, LRU array = %7b at time = %0t", way_onehot, way_out, dut.lru_out, $time);
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
