	.global	clear_cache
	.hidden skip
	.hidden skipdata
	.hidden loopdata
	.hidden skipcode
	.hidden loopcode
	.type	clear_cache, %function
clear_cache:
	adrp	x2, cache_info
	ldr	w4, [x2, #:lo12:cache_info]
	cbnz	w4, skip
	mrs	x4, ctr_el0
	str	w4, [x2, #:lo12:cache_info]
skip:
	tbnz	x4, 28, skipdata
	ubfx	w5, w4, 16, 4
	mov	w3, 4
	lsl	w3, w3, w5
	sub	w2, w3, 1
	bic	x2, x0, x2
loopdata:
	dc	cvau, x2
	add	x2, x2, x3
	cmp	x2, x1
	blo	loopdata
	dsb	ish
skipdata:
	tbnz	x4, 29, skipcode
	ubfx	w5, w4, 0, 4
	mov	w3, 4
	lsl	w3, w3, w5
	sub	w2, w3, 1
	bic	x2, x0, x2
loopcode:
	ic	ivau, x2
	add	x2, x2, x3
	cmp	x2, x1
	blo	loopcode
	dsb	ish
skipcode:
	isb
	ret
	.bss
	.align	2
	.type	cache_info, %object
	.size	cache_info, 4
	.internal cache_info
cache_info:
	.zero	4
