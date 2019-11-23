#  runs in 1385 ns
# this is a 9.32x speedup over a software multiply of these same numbers
.align 4
.section .text
.globl _start
_start:

  la x7, RES
  lw x1, OP1 # use x1 as result register
  lw x2, OP2
  mul x3, x1, x2
  sw x3, 0(x7)
  lw x10, RES

HALT:
  beq x0, x0, HALT
  nop
  nop
  nop



.section .rodata
.balign 256

OP1: .word 411
OP2: .word 385
RES: .word 0x0
