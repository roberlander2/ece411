module div_tb;

tb_itf itf();

logic [31:0] dividend;
logic [31:0] divisor;
logic start_i;
logic rdy;
logic [31:0] quotient;
logic [31:0] quotient_gold;
logic [31:0] remainder;
logic [31:0] remainder_gold;
logic done;
logic signed_i;

divider dut (
    .clk (itf.clk),
    .start_i (start_i),
    .dividend (dividend),
    .divisor (divisor),
    .inputs_signed (signed_i),
    .ready (rdy),
    .quotient (quotient),
    .remainder (remainder),
    .done (done)
);


default clocking tb_clk @(negedge itf.clk); endclocking

// task reset();
//     reset_n <= 1'b0;
//     ##5;
//     reset_n <= 1'b1;
//     ##1;
// endtask : reset

task start();
    start_i <= 1'b1;
    ##1;
    start_i <= 1'b0;
    ##1;
endtask : start

task usign_random_div();
  dividend = $urandom_range(4294967-1);
  divisor = $urandom_range(4294967-1);
  quotient_gold = dividend / divisor;
  remainder_gold = dividend % divisor;
  signed_i = 0;
  start();
  @(tb_clk iff done == 1'b1);
  assert_quotient_equal: assert(quotient == quotient_gold)
                  $display("CORRECT: %0d / %0d = %0d", dividend, divisor, quotient);
    else begin
      $error("BAD QUOTIENT: %0d / %0d = %0d  Gold Result: %0d / %0d = %0d",
          dividend, divisor, quotient,
          dividend, divisor, quotient_gold);
      $finish();
    end
  assert_remainder_equal: assert(remainder == remainder_gold)
                  $display("CORRECT: %0d mod %0d = %0d", dividend, divisor, remainder);
    else begin
      $error("BAD REMAINDER: %0d mod %0d = %0d  Gold Result: %0d mod %0d = %0d",
          dividend, divisor, remainder,
          dividend, divisor, remainder_gold);
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task sign_random_div();
  dividend = $signed($random);
  divisor = $signed($random);
  quotient_gold = $signed(dividend) / $signed(divisor);
  remainder_gold = $signed(dividend) % $signed(divisor);
  signed_i = 1;
  start();
  @(tb_clk iff done == 1'b1);
  assert_quotient_equal: assert($signed(quotient) == $signed(quotient_gold))
                  $display("CORRECT: %0d / %0d = %0d", $signed(dividend), $signed(divisor), $signed(quotient));
    else begin
      $error("BAD QUOTIENT: %0d / %0d = %0d  Gold Result: %0d / %0d = %0d",
          $signed(dividend), $signed(divisor), $signed(quotient),
          $signed(dividend), $signed(divisor), $signed(quotient_gold));
      $finish();
    end
  assert_remainder_equal: assert($signed(remainder) == $signed(remainder_gold))
                  $display("CORRECT: %0d mod %0d = %0d", $signed(dividend), $signed(divisor), $signed(remainder));
    else begin
      $error("BAD REMAINDER: %0d mod %0d = %0d  Gold Result: %0d mod %0d = %0d",
          $signed(dividend), $signed(divisor), $signed(remainder),
          $signed(dividend), $signed(divisor), $signed(remainder_gold));
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task hardcode_sign_div();
  dividend = 32'b0;
  divisor = 32'h0;
  quotient_gold = 32'hFFFFFFFF;
  remainder_gold = 32'h0;
  signed_i = 0;
  start();
  @(tb_clk iff done == 1'b1);
  assert_quotient_equal: assert($signed(quotient) == $signed(quotient_gold))
                  $display("CORRECT: %0d / %0d = %0d", $signed(dividend), $signed(divisor), $signed(quotient));
    else begin
      $error("BAD QUOTIENT: %0d / %0d = %0d  Gold Result: %0d / %0d = %0d",
          $signed(dividend), $signed(divisor), $signed(quotient),
          $signed(dividend), $signed(divisor), $signed(quotient_gold));
      $finish();
    end
  assert_remainder_equal: assert($signed(remainder) == $signed(remainder_gold))
                  $display("CORRECT: %0d mod %0d = %0d", $signed(dividend), $signed(divisor), $signed(remainder));
    else begin
      $error("BAD REMAINDER: %0d mod %0d = %0d  Gold Result: %0d mod %0d = %0d",
          $signed(dividend), $signed(divisor), $signed(remainder),
          $signed(dividend), $signed(divisor), $signed(remainder_gold));
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task unsigned_tests(int count);
  $display("Start Unsigned Divide Tests");
  // reset();
  repeat(count)
    usign_random_div();
  $display("Finish Unsigned Divide Tests");
endtask

task signed_tests(int count);
  $display("Start Signed Divide Tests");
  // reset();
  repeat(count)
    sign_random_div();
  $display("Finish Signed Divide Tests");
endtask

task hardcoded_test();
  $display("Starting Custom Tests");
  // reset();
  hardcode_sign_div();
  $display("Finishing Custom Tests");
endtask


// initial reset_n = 1'b0;
initial begin
  unsigned_tests(1000);
  signed_tests(1000);
  hardcoded_test();
  $finish();
end
endmodule : div_tb
