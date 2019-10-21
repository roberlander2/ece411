mp3_cp1_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that one/two/eight are data labels
    lw x16, byte

    lw x17, half
    lw x18, word
    la x4, byte
    la x5, half
    la x6, word
    lui x7, 12
    lui x8, 255
    lui x9, 16
    lui x10, 33
    srli x7, x7, 12
    srli x8, x8, 12
    srli x9, x9, 12
    srli x10, x10, 12

    sb x7, 0(x4)
    sb x8, 1(x4)
    sb x9, 2(x4)
    sb x10, 3(x4)

    sh x1, 0(x5)
    sh x2, 2(x5)
    sh x3, 4(x5)
    sh x11, 6(x5)

    sw x12, 0(x6)

    lw x13, byte
    lw x14, half
    lw x15, word

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

byte:       .word 0x01234560
half:       .word 0x2E608D1C
word:       .word 0x600D6008
half0:      .word 0xFA39D723
half1:      .word 0x921F0000
half2:      .word 0xA1C20067
half3:      .word 0x024A156E
word0:      .word 0x71AFC3B2
