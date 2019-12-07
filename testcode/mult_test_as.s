# runs in 13205 ns
.align 4
.section .text
.globl _start
_start:

  la x7, RES
  lw x1, OP1 # use x1 as result register
  lw x2, OP2
  addi x3, x1, 0
  addi x2, x2, -1
LOOP:
  add x3, x3, x1
  addi x2, x2, -1
  bgt x2, x0, LOOP
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
