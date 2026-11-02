	.text
	.global	_start
_start:
	mov.l	#0x17ff0, r0
	bra	_main_loop
