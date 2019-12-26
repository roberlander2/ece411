	.file	"strides.c"
	.option nopic
	.hidden	crc_table
	.comm	crc_table,1024,4
	.hidden	crc_table_computed
	.globl	crc_table_computed
	.section	.sbss,"aw",@nobits
	.align	2
	.type	crc_table_computed, @object
	.size	crc_table_computed, 4
crc_table_computed:
	.zero	4
	.text
	.align	2
	.globl	make_crc_table
	.hidden	make_crc_table
	.type	make_crc_table, @function
make_crc_table:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	sw	zero,-24(s0)
	j	.L2
.L7:
	lw	a5,-24(s0)
	sw	a5,-20(s0)
	sw	zero,-28(s0)
	j	.L3
.L6:
	lw	a5,-20(s0)
	andi	a5,a5,1
	beqz	a5,.L4
	lw	a5,-20(s0)
	srli	a4,a5,1
	li	a5,-306675712
	addi	a5,a5,800
	xor	a5,a4,a5
	sw	a5,-20(s0)
	j	.L5
.L4:
	lw	a5,-20(s0)
	srli	a5,a5,1
	sw	a5,-20(s0)
.L5:
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L3:
	lw	a4,-28(s0)
	li	a5,7
	ble	a4,a5,.L6
	lla	a4,crc_table
	lw	a5,-24(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a4,-20(s0)
	sw	a4,0(a5)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L2:
	lw	a4,-24(s0)
	li	a5,255
	ble	a4,a5,.L7
	lla	a5,crc_table_computed
	li	a4,1
	sw	a4,0(a5)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	make_crc_table, .-make_crc_table
	.align	2
	.globl	update_crc
	.hidden	update_crc
	.type	update_crc, @function
update_crc:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	lw	a5,-36(s0)
	sw	a5,-20(s0)
	lla	a5,crc_table_computed
	lw	a5,0(a5)
	bnez	a5,.L9
	call	make_crc_table
.L9:
	sw	zero,-24(s0)
	j	.L10
.L11:
	lw	a5,-24(s0)
	lw	a4,-40(s0)
	add	a5,a4,a5
	lbu	a5,0(a5)
	andi	a5,a5,0xff
	mv	a4,a5
	lw	a5,-20(s0)
	xor	a5,a4,a5
	andi	a5,a5,255
	lla	a4,crc_table
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a4,0(a5)
	lw	a5,-20(s0)
	srli	a5,a5,8
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L10:
	lw	a4,-24(s0)
	lw	a5,-44(s0)
	blt	a4,a5,.L11
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	update_crc, .-update_crc
	.align	2
	.globl	crc
	.hidden	crc
	.type	crc, @function
crc:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	sw	a1,-24(s0)
	lw	a2,-24(s0)
	lw	a1,-20(s0)
	li	a0,-1
	call	update_crc
	mv	a5,a0
	not	a5,a5
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	crc, .-crc
	.align	2
	.globl	xorwow
	.hidden	xorwow
	.type	xorwow, @function
xorwow:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	lla	a5,a.1405
	lw	a5,12(a5)
	sw	a5,-20(s0)
	lla	a5,a.1405
	lw	a5,0(a5)
	sw	a5,-24(s0)
	lla	a5,a.1405
	lw	a4,8(a5)
	lla	a5,a.1405
	sw	a4,12(a5)
	lla	a5,a.1405
	lw	a4,4(a5)
	lla	a5,a.1405
	sw	a4,8(a5)
	lla	a5,a.1405
	lw	a4,-24(s0)
	sw	a4,4(a5)
	lw	a5,-20(s0)
	srli	a5,a5,2
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	slli	a5,a5,1
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	slli	a4,a5,4
	lw	a5,-24(s0)
	xor	a5,a4,a5
	lw	a4,-20(s0)
	xor	a5,a4,a5
	sw	a5,-20(s0)
	lla	a5,a.1405
	lw	a4,-20(s0)
	sw	a4,0(a5)
	lla	a5,counter.1406
	lw	a4,0(a5)
	li	a5,360448
	addi	a5,a5,1989
	add	a4,a4,a5
	lla	a5,counter.1406
	sw	a4,0(a5)
	lla	a5,counter.1406
	lw	a4,0(a5)
	lw	a5,-20(s0)
	add	a5,a4,a5
	mv	a0,a5
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	xorwow, .-xorwow
	.hidden	array
	.comm	array,33554432,4
	.hidden	checksums
	.comm	checksums,128,4
	.align	2
	.globl	_start
	.hidden	_start
	.type	_start, @function
_start:
	li	sp,0x84000000
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	sw	zero,-20(s0)
	j	.L18
.L21:
	sw	zero,-24(s0)
	j	.L19
.L20:
	call	xorwow
	mv	a5,a0
	andi	a4,a5,0xff
	lla	a3,array
	lw	a5,-20(s0)
	slli	a5,a5,5
	add	a3,a3,a5
	lw	a5,-24(s0)
	add	a5,a3,a5
	sb	a4,0(a5)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L19:
	lw	a4,-24(s0)
	li	a5,256
	bne	a4,a5,.L20
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L18:
	lw	a4,-20(s0)
	li	a5,32
	bne	a4,a5,.L21
	sw	zero,-28(s0)
	j	.L22
.L23:
	lw	a5,-28(s0)
	slli	a4,a5,5
	lla	a5,array
	add	a5,a4,a5
	li	a1,256
	mv	a0,a5
	call	crc
	mv	a3,a0
	lla	a4,checksums
	lw	a5,-28(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	sw	a3,0(a5)
	lw	a5,-28(s0)
	addi	a5,a5,1
	sw	a5,-28(s0)
.L22:
	lw	a4,-28(s0)
	li	a5,32
	bne	a4,a5,.L23
	sw	zero,-32(s0)
	j	.L24
.L27:
	lw	a5,-32(s0)
	slli	a4,a5,5
	lla	a5,array
	add	a5,a4,a5
	li	a1,256
	mv	a0,a5
	call	crc
	sw	a0,-36(s0)
	lla	a4,checksums
	lw	a5,-32(s0)
	slli	a5,a5,2
	add	a5,a4,a5
	lw	a5,0(a5)
	lw	a4,-36(s0)
	bne	a4,a5,.L29
	lw	a5,-32(s0)
	addi	a5,a5,1
	sw	a5,-32(s0)
.L24:
	lw	a4,-32(s0)
	li	a5,32
	bne	a4,a5,.L27
	j	.L26
.L29:
	nop
.L26:
	li	a5,0
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	_start, .-_start
	.data
	.align	2
	.type	a.1405, @object
	.size	a.1405, 16
a.1405:
	.word	-1515870811
	.word	-1163018513
	.word	1343934162
	.word	-518918438
	.local	counter.1406
	.comm	counter.1406,4,4
	.ident	"GCC: (GNU) 7.2.0"
