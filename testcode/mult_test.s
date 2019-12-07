#  runs in 1685 ns
# this is a 7.84x speedup over a software multiply of these same numbers
.align 4
.section .text
.globl _start
_start:

  la x7, RES
  lw x1, OP1 # use x1 as result register
  lw x2, OP2
  mul x3, x1, x2
  add x4, x0, x3
  nop
  nop
  nop
  nop
  sw x3, 0(x7)
  lw x10, RES

HALT:
  beq x0, x0, HALT
  nop
  nop
  nop



.section .rodata
.balign 256

OP1: .word 7
OP2: .word 12
RES: .word 0x0
