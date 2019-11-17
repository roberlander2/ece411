factorial.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    lw  x1, factorial
    addi x2, x1, -2
    andi x3, x3, 0
    addi x4, x1, 0
    addi x5, x1, 0
    la  x6, result
    bge x3, x2, store_result

mult:
    add x4, x4, x5
    addi x2, x2, -1
    bne x2, x3, mult

    addi x5, x4, 0
    addi x1, x1, -1
    addi x2, x1, -2
    bne x2, x3, mult

store_result:
    sw x4, 0(x6)
    lw x20, 0(x6)

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

factorial:  .word 0xC
result:     .word 0x0
