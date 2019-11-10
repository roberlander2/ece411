mp3_forwarding_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
    #Add 1 no op in between instructions for WB->EX
    #Add 2 no ops in between instructions for WB->ID
_start:
    #should require Mem->EX forwarding for RS1
    #addi x8, x0, %lo(DataSeg) #add x8, x0, x0 #
    # taken_branches:
    # 	beq x0, x0, forward_br
    # 	lw x7, BAD
    #
    # backward_br:
    # 	beq x0, x0, not_taken_branches
    # 	beq x0, x0, oof1	# Also, test back-to-back branches
    #
    # forward_br:
    # 	beq x0, x0, backward_br
    # 	lw x7, BAD1
    #
    # # Mispredict not-taken branch flushing tests
    # not_taken_branches:
    # 	add x1, x0, 1	# Also, test branching on forwarded value :) WB->CMPin forwarding path needs to be added here
    # 	beq x0, x1, oof	# Don't take (the condition fails)
    #
    # 	beq x0, x0, backward_br_nt # Take
    #
    #
    # forwarding_tests:
    #   	# Forwarding x0 test
    # 	add x3, x3, 1
    # 	add x0, x1, 0
    # 	add x2, x0, 0
    #
    #   beq x2, x3, oof
    #
    #   # Forwarding sr2 imm test
    #   add x2, x1, 0
    #   add x3, x1, 2 # 2 immediate makes sr2 bits point to x2
    #   add x4, x0, 3
    #
    #   bne x3, x4, oof	# Also, test branching on 2 forwarded values :)
    #
    #   # Half word forwarding test -- should not require stalling logic
    # 	lh  x2, FULL
    # 	add x3, x0, -1
    #
    # 	bne x3, x2, oof2
    #
    #
    #   # WB -> MEM forwarding test -- add this path regfilemux -> mem_address and regfilemux_out -> mem_wdata -- This maybe works??
    #   add x3, x1, 1 #2
    #   la x8, TEST
    #   sw  x3, 0(x8)
    #   lw  x4, TEST
    #
    #   bne x4, x3, oof
    #
    #   # Forwarding contention test
    #   add x2, x0, 1
    #   add x2, x0, 2
    #   add x3, x2, 1 # x3 should be 3
    #
    #   beq x3, x2, oof

    lw x1, NOPE
    lw x1, A
    add x5, x1, x0

      lw x7, GOOD

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
    lw x7, BAD
    lw x8, BAD
    nop
    nop
    nop
    nop
    nop                  # Your own programs should also make use
                      # of an infinite loop at the end.


oof:
	lw x7, BAD2
	lw x2, PAY_RESPECTS
	beq x0, x0, halt


oof1:
  lw x7, BAD1
  lw x2, PAY_RESPECTS
  beq x0, x0, halt

oof2:
  lw x7, BAD2
  lw x2, PAY_RESPECTS
  beq x0, x0, halt

backward_br_nt:
  beq x0, x1, oof	# Don't take

  beq x0, x0, halt	# Take


.section .rodata
.balign 256
DataSeg:
	nop
	nop
	nop
	nop
	nop
	nop

PAY_RESPECTS: .word 0xFBADFBAD
BAD:    		  .word 0x00BADBAD
BAD1:         .word 0x11BADBAD
BAD2:         .word 0x22BADBAD
BAD3:         .word 0x33BADBAD
GOOD:         .word 0x600D600D
FULL:	        .word 0xFFFFFFFF
TEST:         .word 0x00000000
	nop
	nop
	nop

A:		.word 0x00000001
NOPE:	.word 0x00BADBAD
	nop
	nop
	nop
