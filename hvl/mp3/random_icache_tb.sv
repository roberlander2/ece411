import rv32i_types::*;

`define HIT_0 0
`define HIT_100 1
`define HIT_50 2
`define HIT_6 3
`define HIT_RATE `HIT_50

`define ZERO_MBE 0

`define NUM_TESTS 1000
`define VERBOSE 1

module random_icache_tb;

timeunit 1ns;
timeprecision 1ns;

/*********************** Variable/Interface Declarations *********************/
tb_itf itf();
int timeout = 100000000;   // Feel Free to adjust the timeout value
int test_count = 0;

rv32i_word mem_address_in;
rv32i_word mem_wdata_in;
logic [3:0] mem_byte_enable_in;
logic mem_read_in;
logic mem_write_in;

rv32i_word mem_rdata_out;
logic mem_resp_out;
logic load_pipeline_out;
logic load_dpipeline;

assign load_dpipeline = 1'b1;
assign mem_resp_out = dut.mem_resp;
/*****************************************************************************/

class RandomCacheInput;
    int hit_count;

    logic [3:0] mbe_range[$];

    rv32i_word mem_address;
    rv32i_word mem_wdata;
    logic [3:0] mem_byte_enable;
    logic mem_read;
    logic mem_write;

    rv32i_word cache_addr0;
    rv32i_word cache_addr1;
    logic [255:0] cache_data0;
    logic [255:0] cache_data1;
    logic [2:0] set;

    logic hit0;
    logic hit1;
    logic lru_out;

    logic dirty0;
    logic dirty1;

    logic [255:0] mem_wdata256;
    rv32i_word mem_byte_enable256;
    logic [255:0] new_data;

    /** Constructor **/
    function new();
        mbe_range.push_back(1);
        mbe_range.push_back(2);
        mbe_range.push_back(4);
        mbe_range.push_back(8);
        mbe_range.push_back(3);
        mbe_range.push_back(12);
        mbe_range.push_back(15);

        hit_count = 0;
    endfunction

    function void cache_input(
        const ref logic [3:0] cpu_mbe_range[$] = mbe_range
    );
        mem_read = 1'b1;
        mem_write = ~mem_read;

        mem_address = $urandom();
        mem_wdata = $urandom();

        // Set mem_byte_enable
        if (mem_read && `ZERO_MBE)
            mem_byte_enable = 4'b0000;
        else begin
            do begin
              mem_byte_enable = $urandom();
            end while (!(mem_byte_enable inside {cpu_mbe_range}));
        end

        if (`HIT_RATE == `HIT_100)
            mem_address[31:9] = 23'b0;
        else if (`HIT_RATE == `HIT_50)
            mem_address[31:10] = 22'b0;
        else if (`HIT_RATE == `HIT_6)
            mem_address[31:13] = 19'b0;

        if (mem_byte_enable == 4'b1111)
            mem_address[1:0] = 2'b00;
        else if (mem_byte_enable == 4'b0011 || mem_byte_enable == 4'b1100)
            mem_address[0] = 1'b0;

        // set immediate value
        set = mem_address[7:5];

        cache_addr0 = {dut.icache_datapath.tag[0].data[set], set, 5'b0};
        cache_addr1 = {dut.icache_datapath.tag[1].data[set], set, 5'b0};
        cache_data0 = dut.icache_datapath.line[0].data[set];
        cache_data1 = dut.icache_datapath.line[1].data[set];

        hit0 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr0[31:8]) && dut.icache_datapath.valid0.data[set];
        hit1 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr1[31:8]) && dut.icache_datapath.valid1.data[set];
        lru_out = dut.icache_datapath.LRU.data[set];

        mem_wdata256 = {8{mem_wdata}};
        mem_byte_enable256 = {28'h0, mem_byte_enable} << (mem_address[4:2]*4);
    endfunction

    function int check_hit_correct();
        hit_count++;
        set = dut.icache_datapath.pipe_cache_cw.address[7:5];
        lru_out = dut.icache_datapath.LRU.data[set];
        cache_addr0 = {dut.icache_datapath.tag[0].data[set], set, 5'b0};
        cache_addr1 = {dut.icache_datapath.tag[1].data[set], set, 5'b0};
        hit0 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr0[31:8]) && dut.icache_datapath.valid0.data[set];
        hit1 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr1[31:8]) && dut.icache_datapath.valid1.data[set];
        if (hit0 && dut.icache_datapath.pipe_cache_cw.mem_read) begin
            assert((mem_rdata_out == dut.icache_datapath.line[0].data[set][(32*dut.icache_datapath.pipe_cache_cw.address[4:2]) +: 32]) &&
                    dut.icache_datapath.LRU.datain == 1'b1 && dut.icache_datapath.LRU.load == 1'b1 && dut.icache_datapath.LRU.windex == set &&
                    dut.icache_datapath.valid0.data[set])
                else begin
                    $display("%1b, %1b, %1b, %1b, %1b", (mem_rdata_out == dut.icache_datapath.line[0].data[set][(32*dut.icache_datapath.pipe_cache_cw.address[4:2]) +: 32]),
                            dut.icache_datapath.LRU.datain == 1'b1, dut.icache_datapath.LRU.load == 1'b1, dut.icache_datapath.LRU.windex == set,
                            dut.icache_datapath.valid0.data[set]);
                    $display("%8h, %8h", mem_rdata_out, dut.icache_datapath.line[0].data[set][(32*dut.icache_datapath.pipe_cache_cw.address[4:2]) +: 32]);
                    $error("Failure on read hit from way 0");
                    return 0;
                end
        end
        else if (hit1 && dut.icache_datapath.pipe_cache_cw.mem_read) begin
            assert((mem_rdata_out == dut.icache_datapath.line[1].data[set][(32*dut.icache_datapath.pipe_cache_cw.address[4:2]) +: 32]) &&
                    dut.icache_datapath.LRU.datain == 1'b0 && dut.icache_datapath.LRU.load == 1'b1 && dut.icache_datapath.LRU.windex == set &&
                    dut.icache_datapath.valid1.data[set])
                else begin
                    $display("%1b, %1b, %1b, %1b, %1b", (mem_rdata_out == dut.icache_datapath.line[1].data[set][(32*dut.icache_datapath.pipe_cache_cw.address[4:2]) +: 32]),
                            dut.icache_datapath.LRU.datain == 1'b0, dut.icache_datapath.LRU.load == 1'b1, dut.icache_datapath.LRU.windex == set,
                            dut.icache_datapath.valid1.data[set]);
                    $error("Failure on read hit from way 1");
                    return 0;
                end
        end
        else begin
            $display("A testbench error has likely occurred - check that mem_read and mem_write are correct: %1b %1b %1b", hit0, hit1, dut.icache_datapath.pipe_cache_cw.mem_read);
            return 0;
        end
        return 1;
    endfunction

    function int check_miss_correct();
        set = dut.icache_datapath.pipe_cache_cw.address[7:5];
        lru_out = dut.icache_datapath.LRU.data[set];
        if (!lru_out) begin
            assert((dut.icache_datapath.line[0].datain == memory.mem[memory.internal_address]) && (dut.icache_datapath.line[0].windex == set) && (dut.icache_datapath.line[0].write_en == 32'hFFFFFFFF) &&
                   (dut.icache_datapath.tag[0].datain == dut.icache_datapath.pipe_cache_cw.address[31:8]) && (dut.icache_datapath.tag[0].windex == set) && (dut.icache_datapath.tag[0].load == 1'b1) &&
                   dut.icache_datapath.valid0.datain == 1'b1 && dut.icache_datapath.valid0.load == 1'b1 && dut.icache_datapath.valid0.windex == set)
                else begin
                  $display("%1b, %1b, %1b, %1b, %1b, %1b, %1b, %1b, %1b", (dut.icache_datapath.line[0].datain == memory.mem[memory.internal_address]), (dut.icache_datapath.line[0].windex == set), (dut.icache_datapath.line[0].write_en == 32'hFFFFFFFF),
                         (dut.icache_datapath.tag[0].datain == dut.icache_datapath.pipe_cache_cw.address[31:8]), (dut.icache_datapath.tag[0].windex == set), (dut.icache_datapath.tag[0].load == 1'b1),
                         dut.icache_datapath.valid0.datain == 1'b1, dut.icache_datapath.valid0.load == 1'b1, dut.icache_datapath.valid0.windex == set);
                  $error("Failure on cache miss into way 0");
                  return 0;
                end
        end
        else if (lru_out) begin
            assert((dut.icache_datapath.line[1].datain == memory.mem[memory.internal_address]) && (dut.icache_datapath.line[1].windex == set) && (dut.icache_datapath.line[1].write_en == 32'hFFFFFFFF) &&
                   (dut.icache_datapath.tag[1].datain == dut.icache_datapath.pipe_cache_cw.address[31:8]) && (dut.icache_datapath.tag[1].windex == set) && (dut.icache_datapath.tag[1].load == 1'b1) &&
                   dut.icache_datapath.valid1.datain == 1'b1 && dut.icache_datapath.valid1.load == 1'b1 && dut.icache_datapath.valid1.windex == set)
                else begin
                  $display("%1b, %1b, %1b, %1b, %1b, %1b, %1b, %1b, %1b", (dut.icache_datapath.line[1].datain == memory.mem[memory.internal_address]), (dut.icache_datapath.line[1].windex == set), (dut.icache_datapath.line[1].write_en == 32'hFFFFFFFF),
                         (dut.icache_datapath.tag[1].datain == dut.icache_datapath.pipe_cache_cw.address[31:8]), (dut.icache_datapath.tag[1].windex == set), (dut.icache_datapath.tag[1].load == 1'b1),
                         dut.icache_datapath.valid1.datain == 1'b1, dut.icache_datapath.valid1.load == 1'b1, dut.icache_datapath.valid1.windex == set);
                  $error("Failure on cache miss into way 0");
                  return 0;
                end
        end
        cache_addr0 = {dut.icache_datapath.tag[0].data[set], set, 5'b0};
        cache_addr1 = {dut.icache_datapath.tag[1].data[set], set, 5'b0};
        cache_data0 = dut.icache_datapath.line[0].data[set];
        cache_data1 = dut.icache_datapath.line[1].data[set];
        hit0 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr0[31:8]) && dut.icache_datapath.valid0.data[set];
        hit1 = (dut.icache_datapath.pipe_cache_cw.address[31:8] == cache_addr1[31:8]) && dut.icache_datapath.valid1.data[set];
        // $display("pipe_address: %6h, cache_addr0: %6h, valid0: %1b, set: %1h", dut.icache_datapath.pipe_cache_cw.address[31:8], cache_addr0[31:8], dut.icache_datapath.valid0.data[set], set);
        // $display("pipe_address: %6h, cache_addr1: %6h, valid1: %1b, set: %1h", dut.icache_datapath.pipe_cache_cw.address[31:8], cache_addr1[31:8], dut.icache_datapath.valid1.data[set], set);
        return 1;
    endfunction
endclass

RandomCacheInput cpu_generator = new();

function void generate_input();
    cpu_generator.cache_input();

    mem_address_in = cpu_generator.mem_address;
    mem_wdata_in = cpu_generator.mem_wdata;
    mem_byte_enable_in = cpu_generator.mem_byte_enable;
    mem_read_in = cpu_generator.mem_read;
    mem_write_in = cpu_generator.mem_write;
endfunction : generate_input

/************************* Error Halting Conditions **************************/
// Stop simulation on memory error detection
always @(posedge itf.clk iff itf.pm_error) begin
    $display("TOP: Halting on Physical Memory Error at time = %0t ps", $time);
end

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

// Simulataneous Memory Read and Write
always @(posedge itf.clk iff (itf.pmem_read && itf.pmem_write))
    $error("@%0t TOP: Simultaneous memory read and write detected", $time);

always_ff @(negedge itf.clk iff (mem_resp_out && dut.icache_ctrl.state.name == "load" && dut.icache_ctrl.next_state.name == "hit_detection")) begin
    if (!cpu_generator.check_miss_correct()) begin
      $error("A cache correctness error occurred on a miss");
      $finish;
    end
end

always_ff @(negedge itf.clk iff (mem_resp_out && dut.icache_ctrl.state.name == "hit_detection")) begin
    if (!cpu_generator.check_hit_correct()) begin
        $error("A cache correctness error occurred on a hit");
        $finish;
    end
end

always_ff @(posedge itf.clk iff (test_count < `NUM_TESTS && load_pipeline_out)) begin
    generate_input();

    if (`VERBOSE)
        $display("Testing stimulus: mem_address = 0x%8h, mem_read = %1b, mem_write = %1b, mem_wdata = 0x%8h, mem_byte_enable = %4b",
            cpu_generator.mem_address, cpu_generator.mem_read, cpu_generator.mem_write, cpu_generator.mem_wdata, cpu_generator.mem_byte_enable);

    test_count <= test_count + 1;
    if (test_count + 1 == `NUM_TESTS) begin
        $display("Finishing Cache Tests: hit rate = %0d / %0d", cpu_generator.hit_count, test_count + 1);
        $finish;
    end
end

/*****************************************************************************/
icache dut(
    .clk                (itf.clk),
    .mem_address        (mem_address_in),
   	.mem_read           (mem_read_in),
    .pmem_resp          (itf.pmem_resp),
    .pmem_rdata         (itf.pmem_rdata),
    .load_dpipeline     (load_dpipeline),
    .mem_rdata          (mem_rdata_out),
    .pmem_read          (itf.pmem_read),
    .pmem_address       (itf.pmem_address),
    .load_pipeline      (load_pipeline_out)
);

pmem_random_cache_tb memory(
    .clk     (itf.clk),
    .read    (itf.pmem_read),
    .write   (itf.pmem_write),
    .address (itf.pmem_address),
    .wdata   (itf.pmem_wdata),
    .resp    (itf.pmem_resp),
    .rdata   (itf.pmem_rdata),
    .error   (itf.pm_error)
);

// task cache_tests(input int count, input logic verbose = 1'b0);
//     $display("Starting Cache Tests");
//     repeat (count) begin
//         cpu_generator.cache_input();
//
//         mem_address_in = cpu_generator.mem_address;
//         mem_wdata_in = cpu_generator.mem_wdata;
//         mem_byte_enable_in = cpu_generator.mem_byte_enable;
//         mem_read_in = cpu_generator.mem_read;
//         mem_write_in = cpu_generator.mem_write;
//
//         if (verbose)
//             $display("Testing stimulus: mem_address = 0x%8h, mem_read = %1b, mem_write = %1b, mem_wdata = 0x%8h, mem_byte_enable = %4b",
//                 cpu_generator.mem_address, cpu_generator.mem_read, cpu_generator.mem_write, cpu_generator.mem_wdata, cpu_generator.mem_byte_enable);
//
//         if (!(cpu_generator.hit0 || cpu_generator.hit1)) begin
//             repeat (2) @(posedge itf.clk);
//             @(negedge itf.clk iff dut.icache_ctrl.state.name == "write_data");
//             if (!cpu_generator.check_miss_correct()) begin
//               $error("A cache correctness error occurred on a miss");
//               $finish;
//             end
//         end
//         @(negedge itf.clk iff mem_resp_out);
//         mem_read_in = 1'b0;
//         mem_write_in = 1'b0;
//         repeat (2) @(posedge itf.clk);
//         if (!cpu_generator.check_hit_correct()) begin
//             $error("A cache correctness error occurred on a hit");
//             $finish;
//         end
//         repeat (2) @(posedge itf.clk);
//     end
//     $display("Finishing Cache Tests: hit rate = %0d / %0d", cpu_generator.hit_count, count);
// endtask
//
// initial begin
//     cache_tests(1000, 1'b1);
//     $finish;
// end

endmodule : random_icache_tb
