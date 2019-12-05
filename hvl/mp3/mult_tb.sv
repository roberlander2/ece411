// import mult_types::*;

module mult_tb;

tb_itf itf();

logic [31:0] multiplier;
logic [31:0] multiplicand;
logic reset_n;
logic start_n;
logic rdy;
logic [63:0] product;
logic [63:0] product_gold;
logic done;
logic signed1;
logic signed2;


multiplier dut (
    .clk_i          ( itf.clk      ),
    .reset_n_i      ( reset_n      ),
    .multiplicand_i ( multiplicand ),
    .multiplier_i   ( multiplier   ),
    .signed1        (signed1       ),
    .signed2        (signed2       ),
    .start_i        ( start_n      ),
    .ready_o        ( rdy          ),
    .product_o      ( product      ),
    .done_o         ( done         )
);


default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    reset_n <= 1'b0;
    ##5;
    reset_n <= 1'b1;
    ##1;
endtask : reset

task start();
    start_n <= 1'b1;
    ##5;
    start_n <= 1'b0;
    ##1;
endtask : start

task usign_random_mult();
  multiplier = $urandom_range(4294967-1);
  multiplicand = $urandom_range(4294967-1);
  product_gold = multiplier * multiplicand;
  signed1 = 0;
  signed2 = 0;
  start();
  @(tb_clk iff done == 1'b1);
  assert_equal: assert(product == multiplier * multiplicand)
                  $display("CORRECT: %0d * %0d = %0d", multiplicand, multiplier, product);
    else begin
      $error("BAD PRODUCT: %0d * %0d = %0d  Gold Result: %0d * %0d = %0d",
          multiplicand, multiplier, product,
          multiplier, multiplicand, product_gold);
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task sign_random_mult();
  multiplier = $signed($random);
  multiplicand = $signed($random);
  product_gold = $signed(multiplier) * $signed(multiplicand);
  signed1 = 1;
  signed2 = 1;
  start();
  @(tb_clk iff done == 1'b1);
  assert_equal: assert($signed(product) == $signed(multiplier) * $signed(multiplicand))
                  $display("CORRECT: %0d * %0d = %0d", $signed(multiplicand),
                                                       $signed(multiplier),
                                                       $signed(product_gold));
    else begin
      $error("BAD PRODUCT: %0d * %0d = %0d  Gold Result: %0d * %0d = %0d",
                                              $signed(multiplicand),
                                              $signed(multiplier),
                                              $signed(product),
                                              $signed(multiplier),
                                              $signed(multiplicand),
                                              $signed(product_gold));
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task hardcode_sign_mult();
  multiplier = -4;
  multiplicand = 964;
  signed1 = 0;
  signed1 = 0;
  start();
  @(tb_clk iff done == 1'b1);
  assert_equal: assert(product == -3856)
                  $display("CORRECT: %0h * %0h = %0h", multiplicand, multiplier,
                            product);
    else begin
      $error("BAD PRODUCT: %0h * %0h = %0h  Gold Result: %0h * %0h = %0h",
                            $signed(multiplicand),
                            $signed(multiplier),
                            $signed(product),
                            multiplier, multiplicand, -3856);
      $finish();
    end
  assert_ready: assert(rdy == 1'b1)
    else begin
      $error("NOT READY ERROR");
      $finish();
    end
endtask

task unsigned_tests(int count);
  $display("Start Unsigned Multiply Tests");
  reset();
  repeat(count)
    usign_random_mult();
  $display("Finish Unsigned Multiply Tests");
endtask

task signed_tests(int count);
  $display("Start Signed Multiply Tests");
  reset();
  repeat(count)
    sign_random_mult();
  $display("Finish Signed Multiply Tests");
endtask

task hardcoded_test();
  $display("Starting Custom Tests");
  reset();
  hardcode_sign_mult();
  $display("Finishing Custom Tests");
endtask


initial reset_n = 1'b0;
initial begin
  //unsigned_tests(1000);
  signed_tests(1000);
  //hardcoded_test();
  $finish();
end
// initial begin
//     reset();
//     /********************** Your Code Here *****************************/
//     //multiply operand
//     for (int i = 0; i < 4294967; i+=73) begin
//       for(int j = 0; j < 4294967; j+=73) begin
//         multiplier <= i;
//         multiplicand <=j;
//         start();
//         @(tb_clk iff done == 1'b1);
//         assert_equal: assert(product == multiplier * multiplicand)
//           else begin
//             $error("BAD PRODUCT: %0d * %0d = %0d  Gold Result: %0d * %0d = %0d", i, j, product, multiplier, multiplicand, multiplier * multiplicand);
//             $finish();
//           end
//         assert_ready: assert(rdy == 1'b1)
//           else begin
//             $error("NOT READY ERROR");
//             $finish();
//           end
//       end
//     end
//
//     reset();
//
//     // //start and reset coverage while the multiplication is running during the add cycle
//     // @(tb_clk);
//     // if(itf.rdy == 1'b1) begin
//     //   start();
//     // end
//     // @(tb_clk iff itf.mult_op == ADD);
//     // start();
//     // assert(itf.rdy == 1'b0);
//     // assert(itf.done == 1'b0);
//     // @(tb_clk iff itf.mult_op == ADD);
//     // reset();
//     // assert(itf.rdy == 1'b1)
//     //   else begin
//     //     $error("NOT READY ERROR");
//     //   end
//     // assert(itf.done == 1'b0)
//     //   else begin
//     //     $error("NOT READY ERROR");
//     //   end
//     //
//     //   reset();
//     //
//     //   //start and reset coverage while the multiplication is running during the shift cycle
//     //   @(tb_clk);
//     //   if(itf.rdy == 1'b1) begin
//     //     start();
//     //   end
//     //   @(tb_clk iff itf.mult_op == SHIFT);
//     //   start();
//     //   assert(itf.rdy == 1'b0);
//     //   assert(itf.done == 1'b0);
//     //   @(tb_clk iff itf.mult_op == SHIFT);
//     //   reset();
//     //   assert(itf.rdy == 1'b1)
//     //     else begin
//     //       $error("%0d: %0t: NOT_READY error detected",`__LINE__,$time);
//     //       report_error(NOT_READY);
//     //     end
//     //   assert(itf.done == 1'b0)
//     //     else begin
//     //       $error("%0d: %0t: NOT_READY error detected",`__LINE__,$time);
//     //       report_error(NOT_READY);
//     //     end
//
//
//
//     /*******************************************************************/
//     $display("Multiply Tests complete");
//     $finish();
//     $error("Improper Simulation Exit");
// end


endmodule : mult_tb
