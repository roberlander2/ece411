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
    add x5, x0, 8 #x5 <- 8
    nop
    nop
    add x6, x5, 2 #x6 <- 8 + 2
    nop
    nop
    nop
    nop
    nop
    nop
    #should require Mem->EX forwarding for RS2
    add x3,x6, 7 #x3 <- 17
    nop
    nop
    add x4, x5, x3 #x4 <- 8 + 17
    nop
    nop
    nop
    nop
    nop
    nop

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

.section .rodata
