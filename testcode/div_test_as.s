# runs in 5795 ns
.align 4
.section .text
.globl _start
_start:

  la x7, RES
  lw x1, OP1 # use x1 as result register
  lw x2, OP2
  addi x3, x1, 0
  andi x4, x4, 0
LOOP:
  sub x3, x3, x2
  addi x4, x4, 1
  bge x3, x2, LOOP
  sw x4, 0(x7)
  lw x10, RES

HALT:
  beq x0, x0, HALT
  nop
  nop
  nop



.section .rodata
.balign 256

OP1: .word 411
OP2: .word 3
RES: .word 0x0
