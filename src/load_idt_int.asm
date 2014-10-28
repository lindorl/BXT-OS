
; Init8259A -----------------------------------------------------------------
Init8259A:
	mov	al, 011h
	out	020h, al		; 主8259, ICW1.
	call	io_delay

	out	0A0h, al		; 从8259, ICW1.
	call	io_delay

	mov	al, 020h		; IRQ0 对应中断向量 0x20
	out	021h, al		; 主8259, ICW2.
	call	io_delay

	mov	al, 028h		; IRQ8 对应中断向量 0x28
	out	0A1h, al		; 从8259, ICW2.
	call	io_delay

	mov	al, 004h		; IR2 对应从8259
	out	021h, al		; 主8259, ICW3.
	call	io_delay

	mov	al, 002h		; 对应主8259的 IR2
	out	0A1h, al		; 从8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al		; 主8259, ICW4.
	call	io_delay

	out	0A1h, al		; 从8259, ICW4.
	call	io_delay

	mov	al, 11111111b	; 屏蔽主8259所有中断
	out	021h, al		; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al		; 从8259, OCW1.
	call	io_delay

	ret
; Init8259A END--------------------------------------------------------------

; PIT -----------------------------------------------------------------------
InitPIT:; 初始化PIT，设置时钟周期为100HZ
	mov al, 34h
	out 43h, al
	
	mov al, 9ch
	out 40h, al
	
	mov al, 2eh
	out 40h, al
	
	ret
; PIT END--------------------------------------------------------------------

; open_handler --------------------------------------------------------------
open_handler:
	mov	al, 11111100b	; 仅仅开启定时器、键盘中断
	out	021h, al		; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al		; 从8259, OCW1.
	call	io_delay

	ret
; open_handler END-----------------------------------------------------------

; io_delay ------------------------------------------------------------------
io_delay:
	nop
	nop
	nop
	nop
	ret
; io_delay END---------------------------------------------------------------

; AdToMM --------------------------------------------------------------------
AdToMM:	;pushad EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI 
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 0 * 4], eax
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 1 * 4], ecx
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 2 * 4], edx
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 3 * 4], ebx
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 4 * 4], esp
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 5 * 4], ebp
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 6 * 4], esi
	mov [start_mm_pos + 3 * 8 * 1024 + 1 + 7 * 4], edi
	ret
; AdToMM END-----------------------------------------------------------------

; MMToAD --------------------------------------------------------------------
MMToAD:	;popad
	mov eax, [start_mm_pos + 3 * 8 * 1024 + 1 + 0 * 4]
	mov ecx, [start_mm_pos + 3 * 8 * 1024 + 1 + 1 * 4]
	mov edx, [start_mm_pos + 3 * 8 * 1024 + 1 + 2 * 4]
	mov ebx, [start_mm_pos + 3 * 8 * 1024 + 1 + 3 * 4]
	mov esp, [start_mm_pos + 3 * 8 * 1024 + 1 + 4 * 4]
	mov ebp, [start_mm_pos + 3 * 8 * 1024 + 1 + 5 * 4]
	mov esi, [start_mm_pos + 3 * 8 * 1024 + 1 + 6 * 4]
	mov edi, [start_mm_pos + 3 * 8 * 1024 + 1 + 7 * 4]
	ret
; MMToAD END-----------------------------------------------------------------

; int_handler ---------------------------------------------------------------
start_mm_pos	equ	0x180000

_ClockHandler:
ClockHandler	equ	_ClockHandler - $$
; process push---------------------------------------------------------------
	call	AdToMM
; process push END-----------------------------------------------------------

	inc	dword [start_mm_pos + 2 * 8 * 1024]
	; 由于每秒循环100次所以当[start_mm_pos + 2 * 8 * 1024 + 7]为100时恰好1秒
	cmp	byte [start_mm_pos + 2 * 8 * 1024 + 7], 100
	jnb	.Clear
	inc byte [start_mm_pos + 2 * 8 * 1024 + 7]
	jmp Send_EOI
	
.Clear:; 使TIMER结构体的time_view项为0
	mov byte [start_mm_pos + 2 * 8 * 1024 + 7], 0
	
Send_EOI:; 发送 EOI
	mov	al, 20h
	out	20h, al	
; process pop----------------------------------------------------------------
	call	MMToAD
; process pop END------------------------------------------------------------

	iretd

_KeyBoardHandler:
KeyBoardHandler	equ	_KeyBoardHandler - $$	
	mov	edx, 20h			;.1	.1--.6 得到按键扫描码
	mov al,	61h				;.2
	out dx, al				;.3
	
	mov edx, 60h			;.4
	mov eax, 0				;.5
	in  al, dx				;.6
	
	cmp al, 7fh				; 由于7fh后的扫描码响应时间为键盘键松开所以剔除
	ja	.Close
	
	; 将KEYBUF结构体的use设置为1,1表示需要处理，0反之
	mov byte [start_mm_pos], 1	
	; 将键盘扫描码传给data
	mov byte [start_mm_pos + 1], al

.Close:	

	iretd
; int_handler END------------------------------------------------------------
