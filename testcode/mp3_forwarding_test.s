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
    taken_branches:
    	beq x0, x0, forward_br
    	lw x7, BAD

    backward_br:
    	beq x0, x0, not_taken_branches
    	beq x0, x0, oof1	# Also, test back-to-back branches

    forward_br:
    	beq x0, x0, backward_br
    	lw x7, BAD1

    # Mispredict not-taken branch flushing tests
    not_taken_branches:
    	add x1, x0, 1	# Also, test branching on forwarded value :)
    	beq x0, x1, oof	# Don't take (the condition fails)

    	beq x0, x0, backward_br_nt # Take

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
    nop
    nop
    nop
    nop
    nop
    nop
    nop                  # Your own programs should also make use
                      # of an infinite loop at the end.


oof1:
  lw x7, BAD3
  lw x2, PAY_RESPECTS
  beq x0, x0, halt
oof:
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

PAY_RESPECTS: .word 0xFFFFFFFF
BAD:    		  .word 0x00BADBAD
BAD1:         .word 0x11BADBAD
BAD2:         .word 0x22BADBAD
BAD3:         .word 0x33BADBAD
GOOD:         .word 0x600D600D
