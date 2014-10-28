
; memcpy --------------------------------------------------------------------
memcpy:
	mov	eax, [esi]
	add	esi, 4
	mov	[edi], eax
	add	edi, 4
	sub	ecx, 1
	jnz	memcpy
	ret
; memcpy END-----------------------------------------------------------------